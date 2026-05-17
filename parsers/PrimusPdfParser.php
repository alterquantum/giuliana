<?php
namespace parsers;

/**
 * Parsa il testo estratto da un PDF PriMus (computo metrico).
 *
 * Âncora di parsing: riga "SOMMANO UM qty prezzo totale".
 * Il codice DEI può essere spezzato su due righe:
 *   CAM26_R02  (prima riga)
 *   .060.010.A (riga successiva)
 * Separatore migliaia nei numeri: ´ (U+00B4), separatore decimale: ,
 */
class PrimusPdfParser {

    // Righe da ignorare nella costruzione della descrizione
    private const SKIP_PATTERNS = [
        '/^(R\s*I\s*P\s*O\s*R\s*T\s*O|RIPORTO)/i',
        '/^(LAVORI\s+(A\s+MISURA|IN\s+ECONOMIA|A\s+CORPO))/i',
        '/^(Num\.?\s*Ord|TARIFFA|DESIGNAZIONE|Quantit|IMPORTI|par\.ug\.|D\s+I\s+M)/i',
        '/^CAM\d+_/i',
        '/^\.[0-9]{3}\.[0-9]{3}\.[A-Z]/i',
        '/^[A-Z]{2,4}\)/i',
        '/^\s*\d+\s*$/',
    ];

    public function parse(string $testo): array {
        $testo = preg_replace('/ +/', ' ', $testo);

        $umPat = 'a\s+corpo|mq|mc|ml|m[²³23]?|kg|t\b|ton\b|h\b|l\b|cad\.?|corpo|corp\.|n\.|pz\.?|kw\b|kwh\b';
        $nPat  = '[0-9][0-9\xB4\x27´\s,\.]*';

        $re = '/\bSOMMAN[OI]\s+(' . $umPat . ')\s+(' . $nPat . ')\s+(' . $nPat . ')\s+(' . $nPat . ')/iu';

        preg_match_all($re, $testo, $sm, PREG_OFFSET_CAPTURE);
        if (empty($sm[0])) return [];

        $voci    = [];
        $prevEnd = 0;
        $n       = count($sm[0]);

        for ($i = 0; $i < $n; $i++) {
            $offset  = $sm[0][$i][1];
            $blocco  = substr($testo, $prevEnd, $offset - $prevEnd);
            $prevEnd = $offset + strlen($sm[0][$i][0]);

            $um      = strtolower(trim(preg_replace('/\s+/', ' ', $sm[1][$i][0])));
            $qty     = $this->parseNum($sm[2][$i][0]);
            $prezzo  = $this->parseNum($sm[3][$i][0]);
            $importo = $this->parseNum($sm[4][$i][0]);

            if ($importo <= 0 && $qty <= 0) continue;

            $voci[] = [
                'numero_voce'     => $this->estraiNumero($blocco),
                'codice_dei'      => $this->estraiCodice($blocco),
                'descrizione'     => $this->estraiDescrizione($blocco),
                'unita_misura'    => $um,
                'quantita'        => $qty,
                'prezzo_unitario' => $prezzo,
                'importo'         => $importo,
            ];
        }

        return $voci;
    }

    private function estraiCodice(string $blocco): string {
        // Codice intero sulla stessa riga: CAM26_R02.060.010.A
        if (preg_match('/\b(CAM\d+_[A-Z][A-Z0-9]*(?:\.[A-Z0-9]+)+\.[A-Z])\b/i', $blocco, $m)) {
            return strtoupper($m[1]);
        }
        // Codice spezzato su due righe: "CAM26_R02\n.060.010.A"
        if (preg_match('/\b(CAM\d+_[A-Z][A-Z0-9]*)\s*\n\s*((?:\.[A-Z0-9]+)+)/i', $blocco, $m)) {
            return strtoupper($m[1] . $m[2]);
        }
        // Codici non-CAM (NP.03, ecc.)
        if (preg_match('/\b([A-Z]{1,4}\.\d{2,}(?:\.\d+)*)\b/', $blocco, $m)) {
            return strtoupper($m[1]);
        }
        return '';
    }

    private function estraiNumero(string $blocco): string {
        foreach (array_map('trim', explode("\n", $blocco)) as $linea) {
            if (preg_match('/^(\d+)\s+[^\d]/', $linea, $m)) return $m[1];
            if (preg_match('/^\d+$/', $linea, $m)) return $m[0];
        }
        return '';
    }

    private function estraiDescrizione(string $blocco): string {
        $parti = [];
        foreach (array_map('trim', explode("\n", $blocco)) as $linea) {
            if ($linea === '') continue;
            $salta = false;
            foreach (self::SKIP_PATTERNS as $pat) {
                if (preg_match($pat, $linea)) { $salta = true; break; }
            }
            if ($salta) continue;
            // Rimuove numero d'ordine iniziale
            $linea = preg_replace('/^\d+\s+/', '', $linea);
            // Rimuove riferimento codice CAM in riga mista
            $linea = preg_replace('/\bCAM\d+_[A-Z][A-Z0-9]*\s*/i', '', $linea);
            // Rimuove suffisso codice tipo ".060.010.A ("
            $linea = preg_replace('/^\.[0-9]+\.[0-9]+\.[A-Z]\s*\(?\s*/i', '', $linea);
            // Rimuove cifra isolata in coda (quantità della riga dimesionale)
            $linea = preg_replace('/\s+[\d\xB4´\',\.]+\s*$/', '', $linea);
            $linea = trim($linea);
            if ($linea !== '') $parti[] = $linea;
        }
        return trim(substr(preg_replace('/\s+/', ' ', implode(' ', $parti)), 0, 400));
    }

    private function parseNum(string $s): float {
        // Rimuove separatori migliaia: ´ (U+00B4), ' , spazi
        $s = preg_replace('/[\xB4´\'\s]/u', '', $s);
        // , come separatore decimale → .
        $s = str_replace(',', '.', $s);
        return (float) trim($s);
    }
}

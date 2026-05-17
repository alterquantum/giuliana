<?php
namespace parsers;

/**
 * Parsa il testo estratto da un PDF PriMus (computo metrico).
 *
 * Âncora: riga "SOMMANO UM qty prezzo totale".
 * Il testo arriva da PDF.js con un \n per pagina; all'interno della pagina
 * le voci sono in sequenza senza newline garantiti.
 *
 * Codice DEI può essere spezzato: "CAM26_R02 ... .060.010.A"
 * Separatore migliaia: ´ (U+00B4) o ' — gestito in parseNum.
 */
class PrimusPdfParser {

    private const HEADER_RE = [
        '/\b(R\s*I\s*P\s*O\s*R\s*T\s*O|RIPORTO)\b/i',
        '/\bLAVORI\s+(A\s+MISURA|IN\s+ECONOMIA|A\s+CORPO)\b/i',
        '/\b(Num\.?\s*Ord\.?|TARIFFA|DESIGNAZIONE\s+DEI\s+LAVORI)\b/i',
        '/\b(par\.ug\.|H\/peso|larg\.|lung\.)\b/i',
        '/\bA\s+R\s*I\s*P\s*O\s*R\s*T\s*A\s*R\s*E\b/i',
        '/\bCOMMITTENTE\b.{0,80}/i',
        '/\bpag\.\s*\d+\b/i',
        '/\bD\s+I\s+M\s+E\s+N\s+S\s+I\s+O\s+N\s+I\b/i',
        '/\bI\s+M\s+P\s+O\s+R\s+T\s+I\b/i',
    ];

    private const UM_PAT = 'a\s+corpo|mq|mc|ml|m[²³23]?|kg|t\b|ton\b|h\b|l\b|cad\.?|corpo|corp\.|n\.|pz\.?|kw\b|kwh\b';

    public function parse(string $testo): array {
        $testo = preg_replace('/ {2,}/', ' ', $testo);
        $re    = '/\bSOMMAN[OI]\s+(' . self::UM_PAT . ')\s+(\S+)\s+(\S+)\s+(\S+)/iu';

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

            if ($qty <= 0 && $importo <= 0) continue;

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
        // Codice intero su un token: CAM26_R02.060.010.A
        if (preg_match('/\b(CAM\d+_[A-Z][A-Z0-9]*(?:\.[A-Z0-9]+)+\.[A-Z])\b/i', $blocco, $m)) {
            return strtoupper($m[1]);
        }
        // Codice spezzato: prefisso "CAM26_R02" + suffisso ".060.010.A" separati da testo
        $hasPrefix = preg_match('/\b(CAM\d+_[A-Z][A-Z0-9]*)/i', $blocco, $mp);
        $hasSuffix = preg_match('/(\.[0-9]{2,3}\.[0-9]{2,3}\.[A-Z])\b/i', $blocco, $ms);
        if ($hasPrefix && $hasSuffix) {
            return strtoupper($mp[1] . $ms[1]);
        }
        // Codici non-CAM (NP.01, NP.02, ecc.)
        if (preg_match('/\b([A-Z]{2,4}\.\d{2,}(?:\.\d+)*)\b/', $blocco, $m)) {
            return strtoupper($m[1]);
        }
        return '';
    }

    private function estraiNumero(string $blocco): string {
        // Numero d'ordine: 1-3 cifre prima di una parola che inizia con maiuscola
        if (preg_match('/\b(\d{1,3})\s+[A-ZÀÈÉÌÒÙ]/u', $blocco, $m)) {
            return $m[1];
        }
        return '';
    }

    private function estraiDescrizione(string $blocco): string {
        $s = $blocco;
        // Rimuove header di pagina
        foreach (self::HEADER_RE as $re) {
            $s = preg_replace($re, ' ', $s);
        }
        // Rimuove parti del codice
        $s = preg_replace('/\bCAM\d+_[A-Z][A-Z0-9]*/i', '', $s);
        $s = preg_replace('/\.[0-9]{2,3}\.[0-9]{2,3}\.[A-Z]\s*\(?\s*/i', '', $s);
        $s = preg_replace('/\b[A-Z]{2,4}\)\s*/i', '', $s);
        // Rimuove numero d'ordine iniziale
        $s = preg_replace('/^\s*\d{1,3}\s+/', '', $s);
        // Rimuove cifre isolate in coda (righe dimensionali)
        $s = preg_replace('/[\s\d,\.´\'*()=+\-]+\s*$/', '', $s);
        return trim(substr(preg_replace('/\s+/', ' ', $s), 0, 400));
    }

    private function parseNum(string $s): float {
        // Rimuove tutto tranne cifre, virgola e punto
        $s = preg_replace('/[^\d,.]/', '', $s);
        if ($s === '') return 0.0;
        // Formato italiano: virgola = decimale, punto = migliaia
        if (strpos($s, ',') !== false && strpos($s, '.') !== false) {
            $s = str_replace('.', '', $s);
            $s = str_replace(',', '.', $s);
        } elseif (strpos($s, ',') !== false) {
            $s = str_replace(',', '.', $s);
        }
        return (float) $s;
    }
}

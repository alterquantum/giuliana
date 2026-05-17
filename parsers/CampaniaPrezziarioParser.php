<?php
namespace parsers;

/**
 * Parsa il testo estratto dal Prezzario Regionale Campania (PDF testo selezionabile).
 *
 * Struttura attesa:
 *   CAM26_A00.010.103         → intestazione di gruppo (no lettera finale)
 *   CAM26_A00.010.103.A ...descrizione multiriga... cad 322.15 70.76 2.12766
 *
 * Colonne numeriche dopo UM: prezzo_unitario [incidenza_manodopera] [rendimento_giornaliero]
 * Separatore decimale: punto (formato PDF Campania).
 */
class CampaniaPrezziarioParser {

    public function parse(string $testo): array {
        $codiceRe = '/\b(CAM\d+_[A-Z][A-Z0-9]*(?:\.[A-Z0-9]+)+)\b/i';
        preg_match_all($codiceRe, $testo, $matches, PREG_OFFSET_CAPTURE);

        if (empty($matches[1])) return [];

        $voci               = [];
        $categoriaCorrente  = '';
        $trovati            = $matches[1];
        $n                  = count($trovati);

        for ($i = 0; $i < $n; $i++) {
            $codice   = $trovati[$i][0];
            $inizio   = $trovati[$i][1] + strlen($codice);
            $fine     = isset($trovati[$i + 1]) ? $trovati[$i + 1][1] : strlen($testo);
            $contenuto = trim(substr($testo, $inizio, $fine - $inizio));

            if (preg_match('/\.[A-Z]$/i', $codice)) {
                $voce = $this->parseVoce($codice, $contenuto, $categoriaCorrente);
                if ($voce !== null) {
                    $voci[] = $voce;
                }
            } else {
                $titolo            = preg_replace('/\s+/', ' ', $contenuto);
                $categoriaCorrente = strtoupper($codice) . ' ' . substr(trim($titolo), 0, 120);
            }
        }

        return $voci;
    }

    private function parseVoce(string $codice, string $contenuto, string $categoria): ?array {
        $um = 'cad\.?|corpo|corp\.|m[²³23]?|mq|mc|ml|kg|t\b|ton\b|h\b|l\b|pz\.?|kw\b|kwh\b|euro\b';
        // UM poi prezzo [incidenza_manodopera] [rendimento_giornaliero] fine stringa
        $pattern = '/\b(' . $um . ')\s+([\d.]+)(?:\s+([\d.]+))?(?:\s+([\d.]+))?\s*$/i';

        if (!preg_match($pattern, $contenuto, $m)) return null;

        $umPos       = strrpos($contenuto, $m[0]);
        $descrizione = preg_replace('/\s+/', ' ', trim(substr($contenuto, 0, $umPos)));

        return [
            'codice'                 => strtoupper($codice),
            'descrizione'            => $descrizione,
            'unita_misura'           => rtrim(strtolower($m[1]), '.'),
            'prezzo_unitario'        => (float) $m[2],
            'incidenza_manodopera'   => !empty($m[3]) ? (float) $m[3] : null,
            'incidenza_materiali'    => null,
            'incidenza_noli'         => null,
            'rendimento_giornaliero' => !empty($m[4]) ? (float) $m[4] : null,
            'squadra_tipo'           => null,
            'attrezzature'           => [],
            'categoria'              => trim($categoria),
        ];
    }
}

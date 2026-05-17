<?php
namespace parsers;

/**
 * Parsa il testo estratto da un PDF PriMus (testo selezionabile).
 * Il testo viene inviato dal frontend via PDF.js e FormData.
 *
 * Struttura attesa di ogni riga voce PriMus:
 *   [num]  [CODICE]  [descrizione]  [U.M.]  [quantità]  [prezzo_unit]  [importo]
 */
class PrimusPdfParser {

    public function parse(string $testo): array {
        $voci   = [];
        $linee  = explode("\n", $testo);
        $buffer = '';

        foreach ($linee as $linea) {
            $linea = trim($linea);
            if ($linea === '') continue;

            // Accumula righe multi-riga (descrizioni lunghe)
            $buffer .= ' ' . $linea;

            // Prova a estrarre una voce completa dal buffer
            $voce = $this->estraiVoce($buffer);
            if ($voce !== null) {
                $voci[] = $voce;
                $buffer = '';
            }
        }

        return $voci;
    }

    private function estraiVoce(string $testo): ?array {
        // Pattern: numero  CODICE  descrizione  U.M.  quantita  prezzo_unit  importo
        // Esempio: 1  A.01.010.a  Scavo a sezione...  m³  125,50  12,34  1.548,67
        $pattern = '/^\s*(\d[\d.]*)\s+'
            . '([A-Za-z][\w.]*\d[\w.]*)\s+'   // codice DEI
            . '(.+?)\s+'                        // descrizione
            . '(m[²³]?|kg|t(?:on)?|l|h|cad\.?|corp\.?|ml|mc|mq|n\.?)\s+'  // U.M.
            . '([\d.,]+)\s+'                    // quantità
            . '([\d.,]+)\s+'                    // prezzo unitario
            . '([\d.,]+)\s*$/iu';

        if (!preg_match($pattern, $testo, $m)) {
            return null;
        }

        return [
            'numero_voce'    => trim($m[1]),
            'codice_dei'     => trim($m[2]),
            'descrizione'    => trim($m[3]),
            'unita_misura'   => trim($m[4]),
            'quantita'       => $this->parseNum($m[5]),
            'prezzo_unitario'=> $this->parseNum($m[6]),
            'importo'        => $this->parseNum($m[7]),
        ];
    }

    private function parseNum(string $s): float {
        // Formato italiano: 1.234,56 → 1234.56
        $s = str_replace('.', '', $s);
        $s = str_replace(',', '.', $s);
        return (float) $s;
    }
}

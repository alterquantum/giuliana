<?php
namespace parsers;

/**
 * Parsa il testo estratto dal prezziario DEI (PDF testo selezionabile).
 *
 * Struttura DEI attesa per ogni voce:
 *   CODICE  Descrizione della lavorazione        U.M.   Prezzo
 *   Incidenza manodopera: X,XX  |  Materiali: X,XX  |  Noli: X,XX
 *
 * Il parser usa una state machine a 3 stati:
 *   CERCA_VOCE → CERCA_INCIDENZE → (torna a CERCA_VOCE)
 */
class DeiPdfParser {

    private string $categoriaCorrente = '';
    private array  $voci = [];

    public function parse(string $testo): array {
        $this->voci              = [];
        $this->categoriaCorrente = '';

        $linee = explode("\n", $testo);
        $stato = 'CERCA_VOCE';
        $voceCorrente = null;

        foreach ($linee as $linea) {
            $linea = trim($linea);
            if ($linea === '') continue;

            // Riconosce intestazione di categoria (es. "A - LAVORI DI SCAVO")
            if ($this->isIntestazione($linea)) {
                $this->categoriaCorrente = $linea;
                $stato = 'CERCA_VOCE';
                continue;
            }

            if ($stato === 'CERCA_VOCE') {
                $voce = $this->estraiVoceDei($linea);
                if ($voce !== null) {
                    $voceCorrente = $voce;
                    $voceCorrente['categoria'] = $this->categoriaCorrente;
                    $stato = 'CERCA_INCIDENZE';
                }

            } elseif ($stato === 'CERCA_INCIDENZE') {
                $inc = $this->estraiIncidenze($linea);
                if ($inc !== null && $voceCorrente !== null) {
                    $voceCorrente = array_merge($voceCorrente, $inc);
                    $this->voci[] = $voceCorrente;
                    $voceCorrente = null;
                    $stato = 'CERCA_VOCE';
                } else {
                    // Nessuna riga incidenza trovata: salva la voce senza incidenze
                    if ($voceCorrente !== null) {
                        $this->voci[] = $voceCorrente;
                        $voceCorrente = null;
                    }
                    // Prova questa stessa riga come nuova voce
                    $voce = $this->estraiVoceDei($linea);
                    if ($voce !== null) {
                        $voceCorrente = $voce;
                        $voceCorrente['categoria'] = $this->categoriaCorrente;
                        $stato = 'CERCA_INCIDENZE';
                    } else {
                        $stato = 'CERCA_VOCE';
                    }
                }
            }
        }

        // Flush eventuale voce pendente
        if ($voceCorrente !== null) {
            $this->voci[] = $voceCorrente;
        }

        return $this->voci;
    }

    private function isIntestazione(string $linea): bool {
        // Riconosce righe tipo "A - SCAVI E MOVIMENTI DI TERRA" o "SEZIONE 1 - ..."
        return (bool) preg_match('/^[A-Z0-9]{1,3}\s*[-–]\s*[A-ZÀÈÌÒÙ]/u', $linea);
    }

    private function estraiVoceDei(string $linea): ?array {
        // Codice DEI: lettere+punti+cifre (es. A.01.010.a, D.04.020)
        $pattern = '/^([A-Za-z][\w.]*\d[\w.]*)\s+(.+?)\s+'
            . '(m[²³]?|kg|t(?:on)?|l|h|cad\.?|corp\.?|ml|mc|mq|n\.?)\s+'
            . '([\d.,]+)\s*$/iu';

        if (!preg_match($pattern, $linea, $m)) return null;

        return [
            'codice'          => trim($m[1]),
            'descrizione'     => trim($m[2]),
            'unita_misura'    => trim($m[3]),
            'prezzo_unitario' => $this->parseNum($m[4]),
            // Incidenze verranno aggiunte dallo stato successivo
            'incidenza_manodopera'    => null,
            'incidenza_materiali'     => null,
            'incidenza_noli'          => null,
            'rendimento_giornaliero'  => null,
            'squadra_tipo'            => null,
            'attrezzature'            => [],
            'categoria'               => '',
        ];
    }

    private function estraiIncidenze(string $linea): ?array {
        // Riga tipo: "Manodopera 5,23  Materiali 6,78  Noli 0,33"
        $result = [];
        $trovato = false;

        if (preg_match('/manodopera[:\s]+([\d.,]+)/iu', $linea, $m)) {
            $result['incidenza_manodopera'] = $this->parseNum($m[1]);
            $trovato = true;
        }
        if (preg_match('/materiali[:\s]+([\d.,]+)/iu', $linea, $m)) {
            $result['incidenza_materiali'] = $this->parseNum($m[1]);
            $trovato = true;
        }
        if (preg_match('/noli[:\s]+([\d.,]+)/iu', $linea, $m)) {
            $result['incidenza_noli'] = $this->parseNum($m[1]);
            $trovato = true;
        }

        return $trovato ? $result : null;
    }

    private function parseNum(string $s): float {
        $s = str_replace('.', '', $s);
        $s = str_replace(',', '.', $s);
        return (float) $s;
    }
}

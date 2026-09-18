# xplot e xplot-veusz

`xplot-veusz` è la versione per [Veusz](https://veusz.github.io/) del vecchio wrapper Perl `xplot` per XmGrace. Accetta dati numerici da file, `.gz` e standard input, genera un documento Veusz `.vsz` con i dati incorporati e lo apre nella GUI. Curve, assi, legenda e dati restano modificabili in Veusz. Il comando originale `xplot` rimane disponibile.

Richiede Python 3.9+ e Veusz installato. Su macOS lo script passa il documento a `/Applications/Veusz.app` tramite Launch Services: se Veusz è già aperto, il nuovo plot usa lo stesso processo e si apre più rapidamente in una nuova finestra. La prima apertura avvia Veusz normalmente; chiudendo tutte le sue finestre, l'app termina e la volta successiva deve riavviarsi. Un alias della shell non è visibile ai processi Python, ma con l'app in quella posizione non serve. Fuori da macOS viene cercato il comando `veusz` nel `PATH`. Per installare lo script in una directory nel `PATH`, copiare **insieme** `xplot-veusz` e `xplot-veusz-colors.json` nella stessa directory.

```sh
./xplot-veusz data.dat
./xplot-veusz -u1:3 -x-1:1 data.1* -u1:2 data.0
cat data.dat | ./xplot-veusz -uall -squick.vsz
./xplot-veusz -stxydy -wlp -l -csolar measurements.dat
./xplot-veusz '-u1:cos($2)' -sfunction.vsz data.dat
./xplot-veusz '-xt$\omega_n$' '-yt$\Sigma_{xx}$' '-L$\chi(i\omega_n)$' data.dat
```

`-sFILE` salva direttamente il documento modificabile `FILE.vsz`. Senza `-s`, ne viene creato uno temporaneo in `/tmp`, che rimane disponibile dopo la chiusura della GUI. `--no-gui` genera il file senza aprire Veusz e ne stampa il percorso. `-show` mostra tutti i comandi Veusz generati. `-h` elenca le opzioni.

Titolo (`-t`), assi (`-xt`, `-yt`) e legenda personalizzata (`-L`, applicata ai file successivi) accettano la [sintassi testuale simile a LaTeX di Veusz](https://veusz.github.io/docs/manual/introduction.html#text): lettere greche come `\omega`, indici `_`, esponenti `^` e frazioni `\frac{a}{b}`. Lo script elimina gli eventuali delimitatori matematici `$...$`, che Veusz non richiede. Non è un interprete LaTeX completo: pacchetti e comandi non previsti da Veusz non vengono renderizzati. Quotare l'argomento nella shell per proteggere `$` e `\`.

Per impostazione predefinita ogni curva ha linea e simboli da **6 pt** (`-wlp -ps2`). Sulle curve con molti punti sono mostrati circa 30 simboli distribuiti lungo tutta la curva, mentre la linea usa tutti i dati. I colori seguono una sequenza di 12 tinte, nell'ordine: nero, rosso, blu, verde, arancione, viola, ciano, magenta, marrone, ottanio, oliva e grigio scuro; dalla tredicesima curva la sequenza ricomincia. `-wl`, `-wp`, `-psN` e `-cSCHEME` sostituiscono queste impostazioni quando servono stili diversi.

## Opzioni compatibili

| Opzione | Effetto |
| --- | --- |
| `-u1:2,1:3`, `-uall`, `-uone` | Colonne numerate da 1; tutte le colonne successive alla prima; coppia predefinita |
| `-u1:'cos($2)'` | Trasformazioni matematiche delle colonne (`$N`), anche con più colonne nella stessa formula |
| `-stxy`, `-stxydx`, `-stxydy`, `-stxydxdy` | Curve XY e barre d'errore simmetriche |
| `-xMIN:MAX`, `-yMIN:MAX`, `-lx`, `-ly` | Limiti degli assi e scala logaritmica |
| `-tTEXT`, `-xtTEXT`, `-ytTEXT` | Titolo ed etichette degli assi |
| `-LTEXT` | Testo della legenda per i file successivi; attiva la legenda |
| `-wl`, `-wp`, `-wlp[:N]`, `-lwN`, `-psN` | Linee, simboli, spessori e dimensioni; predefinito `-wlp -ps2` |
| `-l`, `-d[N]`, `-kN` | Legenda per file/directory; spostamento verticale delle curve |
| `-cSCHEME`, `-clist` | Gradienti `default`, `solar`, `jamaica`, `rainbow`, `matplotlib` o colori X11/hex separati da `:`; elenco nomi |
| `-m[WIDTH:HEIGHT]` | Dimensioni della pagina; pixel convertiti assumendo 96 dpi |
| `-sFILE`, `-show`, `--no-gui` | Salvataggio, ispezione dei comandi e uso senza GUI |

Le opzioni `-u`, `-st`, `-w`, `-lw`, `-ps` e `-k` possono comparire tra i file e si applicano a quelli successivi. I blocchi separati da righe vuote diventano curve distinte. I dati sono incorporati nel `.vsz`, quindi il documento non dipende dai file originali, compresi stdin e `.gz`.

Le espressioni sono valutate sui dati durante la generazione e i risultati sono salvati nel documento; le formule non restano collegate ai dati sorgente. Le opzioni globali per assi, titolo, legenda e palette prendono l'ultimo valore specificato. Alcuni dettagli estetici di XmGrace non hanno un equivalente identico in Veusz, in particolare font e numerazione dei simboli.

La [documentazione ufficiale dell'API Veusz](https://veusz.github.io/docs/manual/api.html) descrive i comandi usati nel `.vsz`; la [guida ai dataset](https://veusz.github.io/docs/manual/datasets.html) descrive come modificarli dalla GUI.

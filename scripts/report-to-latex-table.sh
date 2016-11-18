#!/usr/bin/env bash

echo '
\begin{table}[!ht]
  \begin{center}
    \begin{tabular}{| l | l |}
    \hline'
sed -r '1d' | \
cut -f1-2 -d, | \
sed -r 's;File name;\\textbf\{Nome do arquivo\};g' | \
sed -r 's;Above stego threshold;\\textbf\{Acima do \\emph\{threshold\}\};g' | \
sed -r 's;,; \& ;g' | \
sed -r 's;$; \\\\ \\hline;g' | \
sed -r 's;^(.*.jpg);\\texttt{\1};g' | \
sed -r 's;_;\\_;g' | \
sed -r 's;false;Não;g' | \
sed -r 's;true;Sim;g'
echo '    \end{tabular}
  \end{center}
  \caption{}
  \label{tab:}
\end{table}
'

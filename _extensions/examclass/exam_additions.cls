% ---------- Conditional Question Title ---------- %

\makeatletter
\newif\ifIsTitledQuestion
\def\ifIsTitledQuestion{%
  \ifnum\pdfstrcmp{\thequestiontitle}{\thequestion}=0 %
    \expandafter\@secondoftwo
  \else
    \expandafter\@firstoftwo
  \fi
  {\IsTitledQuestiontrue}%
  {\IsTitledQuestionfalse}%
  \ifIsTitledQuestion
}
\makeatother

\makeatletter
\newcommand{\conditionalQuestionTitle}{%
  \ifIsTitledQuestion
    \thequestiontitle
  \else
    \@empty
  \fi
}
\makeatother

% ---------- Multicol Checkboxes Environment ---------- %
% This environment allows for a list of checkboxes that are displayed in two columns.
% Usage:
% \begin{multicolcheckboxes}
%     \choice This is a choice
%     \CorrectChoice This is another choice
%     \choice This is yet another choice
% \end{multicolcheckboxes}

\newenvironment{multicolcheckboxes}{%

\begin{checkboxes}\begin{multicols}{2}%
}{%
\end{multicols}\end{checkboxes}%

}

% ---------- True/False Environment ---------- %
% This defines a true/false environment that takes an optional argument for the column header (such as "statements" or "assertions"). Usage:
% \begin{true_false_questions}[Statements]
%     \tfitem{Statement 1.}{T}
%     \tfitem{Statement 2.}{F}
%     \tfitem{Statement 3.}{T}
% \end{true_false_questions}

\newenvironment{true_false_questions}[1][]{%
    \vspace{0.5em}
    \begin{tabular}[t]{p{0.7\textwidth}cc}
    \textbf{#1} & \textbf{True} & \textbf{False} \\
    \hline
    \noalign{\vspace{2pt}}
}{%
    \end{tabular}
}


\newcommand{\tfitem}[2]{%
    #1 & \TrueFalseChoice{#2} & \TrueFalseChoice{\ifstrequal{#2}{T}{F}{T}} \\[2pt]
}

\makeatletter
\newcommand*{\TrueFalseChoice}[1]{%
    \ifprintanswers
        \ifthenelse{\equal{#1}{T}}{%
        {\color@begingroup\CorrectChoice@Emphasis\checked@char
        \color@endgroup}%

        }{%
        \checkbox@char
        }%
    \else
    \checkbox@char
    \fi
}
\makeatother

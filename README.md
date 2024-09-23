# ExamClass Extension For Quarto

Extension for creating exams in R Markdown using the exam class package in Latex.

## Installing


```bash
quarto add KBurbank/examclass
```

This will install the extension under the `_extensions` subdirectory.
If you're using version control, you will want to check in this directory.

## Using

Make your document using RMarkdown as usual. You should select the format `examQuestion-pdf` in the YAML header, as in the example. You can add questions using \question or \titledquestion as per the exam class documentation. If you are including individual question files, you can save them in the Questions subdirectory and use the `{{< include Questions/filename.qmd >}}` tag in the main document. For these subquestions, you don't need to include `\begin{questions}` or `\end{questions}`, because the yaml file inside the Questions directory instructs Quarto to add them when you render them individually. 

## Example

Here is the source code for a minimal example: [example.qmd](example.qmd).


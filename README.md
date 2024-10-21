# Examclass Extension For Quarto

This extension allows you to use the LaTeX [Exam Class](https://math.mit.edu/~psh/exam/examdoc.pdf) document class to write exams in Quarto and R Markdown. You can use standard `examclass`LaTeX commands to format your exam, and include R code and other content using standard RMarkdown syntax.

The extension provides two pdf output formats, `examclass-pdf` and `examclass-pdf+solutions`. By listing both formats in the header of your document, you can easily render both the student version and the solutions of your exam.

Additionally, the extension provides two question types beyond those provided by the `examclass` package: a true/false question, and a multiple choice question with the answers in two columns. See the [question_types.qmd](question_types.qmd) file for more information.



## Installing


To start writing a new exam, you can use the following command fro to install this extension along with a minimal template:

```
quarto use template KBurbank/examclass
```
This will prompt you to create a new directory with the extension and a basic exam template for you to modify.

Alternatively, you can add the extension to an existing project:

```
quarto add KBurbank/examclass
```

This will install the extension under the `_extensions` subdirectory in your current working directory.

For more information on installing and using Quarto extensions, see the [Quarto documentation](https://quarto.org/docs/extensions/managing.html).

## Usage

The easiest way to get started writing an exam is to modify the [minimal template](template.qmd) provided by the extension when you use `quarto use template`.

If you're not using the template, you should set the format in the YAML header of your existing document to `examclass-pdf`. Additionally, you can add a format for the solutions document by adding `examclass-pdf+solutions`:

```
format:
  examclass-pdf:
    keep-tex: true
  examclass-pdf+solutions:
    keep-tex: true
```


Then, you should format your document using the Latex commands defined in the [Exam Class documentation](https://math.mit.edu/~psh/exam/examdoc.pdf). You will place questions inside a `questions` environment, and indicate individual questions using the `\question` command or `\titledquestion` commands:

```
\begin{questions}

\question This is a question

\titledquestion{This is a titled question}
\end{questions}
```

You can use question parts, points solutions, and any of the other features defined in the exam class package.

Questions, parts, and solutions may also include any standard Quarto content, including R chunks.

## Rendering

To render your exam, use the `Render` button in RStudio as usual. If you click on the disclosure triangle to the right of the `Render` button, you can select whether to render the student version of the exam (`examclass-pdf`) or the solutions (`examclass-pdf+solutions`). The solutions document will have the same name as the student version of the exam, but with `+solutions` appended.


## Example

Here is the source code for a minimal example: [template.qmd](template.qmd). The student version of the exam is rendered as [template.pdf](template.pdf), and the solutions are rendered as [template+solutions.pdf](template+solutions.pdf).

To see more examples of how to use the extension, look at the [question_types.qmd](question_types.qmd) file. The student version of the exam is rendered as [question_types.pdf](question_types.pdf), and the solutions are rendered as [question_types+solutions.pdf](question_types+solutions.pdf).


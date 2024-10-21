# ExamClass Extension For Quarto

Extension for creating exams in Quarto and R Markdown using the exam class package in Latex.

## Installing


To start writing a new exam, you can use the following command to start with a minimal template:

```
quarto use template KBurbank/examclass
```
This will create a new directory with a basic template for you to modify.

Alternatively, you can add the extension to an existing project:

```
quarto add KBurbank/examclass
```

This will install the extension under the `_extensions` subdirectory in your document folder.



## Using

The easiest way to get started writing an exam is to modify the [minimal template](template.qmd) provided by the extension.

If you're not using the template, you should set the format in the YAML header of your document to `examclass-pdf`. Additionally, you can add a format for the solutions document by adding `examclass-pdf+solutions`:

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

To render your exam, use the `Render` button in RStudio as usual. If you click on the disclosure triangle to the right of the `Render` button, you can select whether to render the student version of the exam or the solutions.


## Example

Here is the source code for a minimal example: [template.qmd](template.qmd). The student version of the exam is rendered as [template.pdf](template.pdf), and the solutions are rendered as [template+solutions.pdf](template+solutions.pdf).

To see more examples of how to use the extension, look at the [question_types.qmd](question_types.qmd) file. The student version of the exam is rendered as [question_types.pdf](question_types.pdf), and the solutions are rendered as [question_types+solutions.pdf](question_types+solutions.pdf).


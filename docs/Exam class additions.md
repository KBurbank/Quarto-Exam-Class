# Exam Class Additions Documentation

This documentation covers the additional features provided by the `examadditions.cls` class file, which extends the functionality of the standard LaTeX `exam` class.

## Features

### 1. Conditional Question Titles

The class provides a mechanism for conditional question titles using `\conditionalQuestionTitle`. This will display the question title, if it is a titled question, and be empty otherwise. (By contrast, the built-in `\thequestiontitle` will display the question number if the question is untitled.)

It is useful when setting the question title formatting. For instance, 

```{=latex}
\qformat{%
            \textbf{\thequestion.}%
            \textit{ \conditionalQuestionTitle}\hfill (\totalpoints\ points in total)
            }
```

This will display the question number and title if the question is titled, and just the question number if the question is untitled. In both cases, the total points are displayed to the right.

### 2. Multi-Column Checkboxes

The `multicolcheckboxes` environment is a wrapper that puts the `checkboxes` environment inside a `multicol` environment, creating a two-column layout for multiple-choice answers.


Usage:

```{=latex}
\begin{multicolcheckboxes}
\choice Option A
\CorrectChoice Option B
\choice Option C
\choice Option D
\end{multicolcheckboxes}
```

### 3. True/False Questions

The `true_false_questions` environment creates a formatted table for true/false questions.

Usage:

```latex
\begin{true_false_questions}[Statements]
\tfitem{The sky is blue.}{T}
\tfitem{The Earth is flat.}{F}
\end{true_false_questions}
```


## Implementation Details

### Conditional Question Titles

The class defines a new conditional `\ifIsTitledQuestion` and a command `\conditionalQuestionTitle` to handle conditional question titles.

### Multi-Column Checkboxes

The `multicolcheckboxes` environment is defined using the `multicol` package to create a two-column layout within the standard `checkboxes` environment.

### True/False Questions

The `true_false_questions` environment creates a formatted table for true/false questions. It uses the `\TrueFalseChoice` command to handle the display of correct answers when `\printanswers` is enabled.


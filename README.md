# TikzToPdf

Compiles a file containing only TikZ directives to a PDF
using pdflatex.

## Dependencies

Depends on ECLA and BashUtils.

## Install

Install TikzToPdf to $HOME/bin by simply typing
```sh
$ make install
```
If you prefer another location, e.g., /usr/local/bin, type
```sh
$ PREFIX="/usr/local" make install
```

## Uninstall

If you installed TikzToPdf to the default location (i.e., $HOME/bin), 
uninstall it by typing
```sh
$ make uninstall
```
If you specified a different location, e.g., /usr/local/bin, type
```sh
$ PREFIX="/usr/local" make uninstall
```

## Usage

Create a file that contains TikZ directives, e.g.,
```sh
$ cat myfigure.tikz.tex
\node[circle,draw=red] { Hello there!};
```
and compile it to a PDF file myfigure.pdf:
```sh
$ tikztopdf myfigure.tikz.tex
```


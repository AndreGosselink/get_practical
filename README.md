# Get Practical Flow Cytometry
The 4th edition of „Practical Flow Cytometry“ by H.M.Shapiro is made publicly avaialably, curtesy of Beckman Coulter at:

[www.beckman.com](https://www.beckman.com/resources/reading-material/ebooks/practical-flow-cytometry)  

They provide it in a nice online viewer, which even allows to print pages out. This
This script fetches pages from their online viewer and stores them as a single PDF
It provides the same functionality as their online viewer print function,
but as a nice CLI script.

# Usage
get_practical \<frompage\> \<topage\>  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\<frompage\> First page to start from  
&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;\<topage\> Last page inclusive (must be larger than \<frompage\>)

# Requirements
- [GhostScript](https://www.ghostscript.com/)
- [OCRmyPDF](https://ocrmypdf.readthedocs.io/en/latest/)
- [wget](https://www.gnu.org/software/wget/)
- [pdfunite](https://poppler.freedesktop.org/) (optional)

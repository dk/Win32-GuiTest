:: $Id: makepod.bat,v 1.2 2004/03/21 07:59:44 ctrondlp Exp $
call podchecker %1.pm
call pod2text <%1.pm >%1.txt
call pod2html <%1.pm >%1.html

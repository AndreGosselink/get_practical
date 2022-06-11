#!/bin/bash

declare HASUNITE

# utility merge pdfs
_merge_pdfs () {
    dpi=$1
    outputfile=$2
    inputfiles=${@:3}

    pscommands="<< /ColorACSImageDict << /VSamples [ 1 1 1 1 ] /HSamples [ 1 1 1 1 ] /QFactor 0.08 /Blend 1 >> /ColorImageDownsampleType /Bicubic /ColorConversionStrategy /LeaveColorUnchanged >> setdistillerparams"
    
    # echo "${dpi} | ${outputfile} | ${inputfiles} "
    gs -q -dNOPAUSE -dBATCH -dSAFER                \
              -sDEVICE=pdfwrite                    \
              -dCompatibilityLevel=1.5             \
              -dEmbedAllFonts=true                 \
              -dSubsetFonts=true                   \
              -dAutoRotatePages=/None              \
              -dColorImageDownsampleType=/Bicubic  \
              -dColorImageResolution=${dpi}        \
              -dGrayImageDownsampleType=/Bicubic   \
              -dGrayImageResolution=${dpi}         \
              -dMonoImageDownsampleType=/Subsample \
              -dMonoImageResolution=${dpi}         \
              -sOutputFile=${outputfile}           \
              -sPAPERSIZE=letter                   \
              -dFIXEDMEDIA                         \
              -dPDFFitPage                         \
              ${inputfiles}                        \
              -dPDFSETTINGS=/prepress -c ${pscommands}
}

merge_parts () {
    partsdir=$1
    ebookpath=$2
    dpi=$3
    
    pdfparts=($(ls -dv ${partsdir}/*.pdf))
    if [ ${HASUNITE} -eq 0 ];
    then
        printf "Using ghostscript (might crash on large files)"
        _merge_pdfs ${dpi} ${ebookpath} ${pdfparts[@]} 
    else
        printf "Using pdfunite"
        pdfunite ${pdfparts[@]} ${ebookpath}
    fi
}

merge_pages () {
    pagesperpart=$1
    pdfpagedir=$2
    partsdir=$3
    dpi=$4
    mkdir -p ${partsdir}

    pdfpages=($(ls -dv ${pdfpagedir}/*.pdf))
    currentpart=1
    part=1
    for i in $(seq 0 $pagesperpart ${#pdfpages[@]})
    do
        partpath=${partsdir}/part_${part}.pdf
        if [ -f ${partpath} ];
        then 
            printf "Keeping existing part ${part} (${i}-$((i + pagesperpart)))\n" 
        else
            printf "Merging pages ${i} - $((i + pagesperpart))\n" 
            partpages=${pdfpages[@]:$i:$pagesperpart}
            # echo $partpages
            _merge_pdfs ${dpi} ${partpath} ${partpages} 
            # printf "DONE\n"
        fi
        ((part=part+1))
    done
}

fetch_pages () {
    frompage=$1
    topage=$2
    imgdir=$3
    ocrdir=$4
    baseurl=$5
    dpi=$6
    mkdir -p ${imgdir}
    mkdir -p ${ocrdir}

    for i in $(seq -f %04g ${frompage} 1 ${topage})
    do
        imgdst=${imgdir}/page${i}.jpg
        pdfdst=${ocrdir}/page${i}.pdf

        # download
        if [ -f ${imgdst} ]; then
            printf "Using existing image ${i}/${topage}..."
        else
            printf "Fetching page ${i}/${topage}..."
            wget -q ${baseurl}/page${i}_l.jpg -O ${imgdst} # > /dev/null 2>&1
            if [ $? -ne 0 ];
            then
                printf " could not fetch page!\n"
                rm -f ${imgdst}
                continue
            fi
        fi

        # convert
        if [ -f ${pdfdst} ]; then
            printf " using existing pdf ${i}/${topage}..."
        else
            printf " converting to PDF with OCR..."
            # --clean-final omitted
            ocrmypdf                                    \
                --image-dpi=${dpi}                      \
                --language=eng                          \
                --pdfa-image-compression=lossless       \
                --jpeg-quality=100                      \
                --output-type=pdfa                      \
                --optimize=1                            \
                ${imgdst} ${pdfdst} > /dev/null 2>&1
            if [ $? -ne 0 ];
            then
                printf " could not convert!\n"
                rm -f ${pdfdst}
                continue
            fi
        fi
        printf " Done!\n"
    done
}

DPI=96
URL="https://apps.beckman.com/books/flowcytometry/practicalflowcytometry/files/assets/common/page-html5-substrates"
OCRDIR="ocr"
IMGDIR="img"
PARTDIR="parts"
# FROMPAGE=1
# TOPAGE=736
FROMPAGE=${1}
TOPAGE=${2}
PAGESPERPART=200

show_help () {
    printf "Usage:\n$0 <frompage> <topage>\n"
    printf "\t <frompage> First page to start from\n"
    printf "\t <topage> Last page inclusive (must be larger than <frompage>)\n"
}

if [ "$FROMPAGE" == "-h" ];
then
    show_help
    exit 0
fi

if [ $FROMPAGE -gt $TOPAGE ];
then
    printf "frompage=${FROMPAGE} is larger than topage=${TOPAGE}!\n"
    exit -1
fi
if [ -z "$FROMPAGE" ];
then
    show_help
    exit -1
fi
if [ -z "$TOPAGE" ];
then
    show_help
    exit -1
fi


_WGETVERSION=($(wget --version 2> /dev/null))
if [ $? -ne 0 ];
then
    printf "Wget command 'wget' not found!\n"
    exit -1
else
    # _WGETVERSION=${_WGETVERSION[@]:0:3}
    # printf "Found wget version %s\n" "${_WGETVERSION/#/ }"
    printf "Found wget version %s\n" "${_WGETVERSION[2]}"
fi

_GSVERSION=$(gs --version 2> /dev/null)
if [ $? -ne 0 ];
then
    printf "Ghostscript command 'gs' not found!\n"
    exit -1
else
    printf "Found ghostscript version %s\n" "${_GSVERSION}"
fi

_OCRMYPDFVERSION=$(ocrmypdf --version 2> /dev/null)
if [ $? -ne 0 ];
then
    printf "OCR command 'ocrmypdf' not found!\n"
    exit -1
else
    printf "Found ocrmypdf version %s\n" "${_OCRMYPDFVERSION}"
fi

_UNITEPDFVERSION=($(pdfunite -v 2>&1))
if [ $? -ne 0 ];
then
    printf "Unitepdf command 'unitepdf' not found, falling back to ghostscript for finall merge (might crash)"
    HASUNITE=0
else
    # _UNITEPDFVERSION=${_UNITEPDFVERSION[@]:2:1}
    printf "Found unitepdf version %s\n" "${_UNITEPDFVERSION[2]}"
    HASUNITE=1
fi

printf "\nFetching and processing pages...\n"
fetch_pages ${FROMPAGE} ${TOPAGE} ${IMGDIR} ${OCRDIR} ${URL} ${DPI}

printf "\nMerging pages to parts\n"
merge_pages ${PAGESPERPART} ${OCRDIR} ${PARTDIR} ${DPI}

printf "\nFinalizing 'practical_flow_${FROMPAGE}-${TOPAGE}.pdf'\n"
merge_parts ${PARTDIR} "practical_flow_${FROMPAGE}-${TOPAGE}.pdf" ${DPI}
printf "Done!\n"

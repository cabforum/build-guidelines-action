FROM pandoc/latex:3.4.0.0

# Update tlmgr if necessary
RUN tlmgr option repository ftp://tug.org/historic/systems/texlive/2020/tlnet-final
RUN tlmgr update --self

# Install the necessary LaTeX packages
RUN tlmgr install \
  crimsonpro \
  # Work around https://bugs.archlinux.org/task/67856 - needed by xecjk
  ctex \
  draftwatermark \
  enumitem \
  everypage \
  fancyhdr \
  floatrow \
  latexdiff \
  multirow \
  parskip \
  sourcecodepro \
  sourcesanspro \
  sourceserifpro \
  titlesec \
  tocloft \
  xecjk

# Install bash, coreutils and git
RUN apk add --no-cache bash coreutils git

# Install NotoSerif fonts
RUN mkdir -p /tmp/fonts && \
    mkdir -p /usr/share/fonts && \
    wget -O /tmp/fonts/noto.zip https://noto-website-2.storage.googleapis.com/pkgs/NotoSerifCJKjp-hinted.zip && \
    unzip /tmp/fonts/noto.zip -d /tmp/fonts && \
    chmod 0644 /tmp/fonts/*.otf && \
    cp /tmp/fonts/*.otf /usr/share/fonts && \
    fc-cache -f -v && \
    rm -rf /tmp/fonts

# Install Python3 and Pantable
RUN apk add --update --no-cache python3 py3-pip py3-numpy
RUN python3 -m pip install pyyaml==5.3.1
RUN python3 -m pip install pantable==0.13.4

RUN mkdir -p /cabforum
RUN mkdir -p /cabforum/templates
RUN mkdir -p /cabforum/filters

RUN wget -O /cabforum/filters/pandoc-list-table.lua "https://raw.githubusercontent.com/bpj/pandoc-list-table/94121a7dae0cb1300fde5ecc5268d3a58fed3d91/pandoc-list-table.lua"

COPY entrypoint.sh /cabforum/entrypoint.sh
COPY templates/ /cabforum/templates/
COPY filters/ /cabforum/filters/

ENTRYPOINT ["/cabforum/entrypoint.sh"]

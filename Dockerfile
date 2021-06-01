FROM pandoc/latex:2.14

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
  latexdiff \
  multirow \
  parskip \
  sourcecodepro \
  sourcesanspro \
  sourceserifpro \
  titlesec \
  tocloft \
  xecjk

# Install bash
RUN apk add bash coreutils

RUN mkdir -p /tmp/fonts && \
    mkdir -p /usr/share/fonts && \
    wget -O /tmp/fonts/noto.zip https://noto-website-2.storage.googleapis.com/pkgs/NotoSerifCJKjp-hinted.zip && \
    unzip /tmp/fonts/noto.zip -d /tmp/fonts && \
    chmod 0644 /tmp/fonts/*.otf && \
    cp /tmp/fonts/*.otf /usr/share/fonts && \
    fc-cache -f -v && \
    rm -rf /tmp/fonts

RUN mkdir -p /cabforum
RUN mkdir -p /cabforum/templates
RUN mkdir -p /cabforum/filters

COPY entrypoint.sh /cabforum/entrypoint.sh
COPY templates/ /cabforum/templates/
COPY filters/ /cabforum/filters/

ENTRYPOINT ["/cabforum/entrypoint.sh"]

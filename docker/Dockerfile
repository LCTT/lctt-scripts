FROM base/archlinux
RUN pacman -Syy --noconfirm && pacman -Syu --noconfirm && pacman -S openssh git s-nail jq html2text pandoc python-pip --noconfirm && yes |pacman -Scc
RUN useradd -m lctt
WORKDIR /home/lctt
COPY starter.sh .
RUN mkdir TranslateProject 
RUN chown -R lctt:lctt /home/lctt
VOLUME ["/home/lctt/TranslateProject"]
USER lctt
ENTRYPOINT ["/home/lctt/starter.sh"]
CMD ["/bin/bash"]
FROM archlinux/base
#RUN pacman -Syy --noconfirm && pacman -Syu --noconfirm && pacman -S openssh git s-nail jq html2text pandoc python-pip tidy --noconfirm && yes |pacman -Scc
RUN pacman -Syy --noconfirm && pacman -Syu --noconfirm && pacman -S openssh git s-nail jq html2text pandoc python-pip tidy --noconfirm && pacman -Scc --noconfirm
RUN sed -i 's/#zh_CN.UTF-8/zh_CN.UTF-8/' /etc/locale.gen && locale-gen
ENV LANG=zh_CN.UTF-8
RUN useradd -m lctt
WORKDIR /home/lctt
COPY starter.sh .
RUN mkdir TranslateProject 
RUN chown -R lctt:lctt /home/lctt
VOLUME ["/home/lctt/TranslateProject"]
USER lctt
ENTRYPOINT ["/home/lctt/starter.sh"]
CMD ["/bin/bash"]

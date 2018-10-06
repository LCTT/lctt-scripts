FROM base/archlinux
RUN pacman -Syy --noconfirm && pacman -Syu --noconfirm && pacman -S openssh git s-nail jq html2text pandoc python-pip --noconfirm && yes |pacman -Scc
RUN useradd -m lctt
WORKDIR /home/lctt
RUN git clone https://github.com/LCTT/lctt-scripts && sed -i '/ProjectRoot=/cProjectRoot=~/TranslateProject' ./lctt-scripts/lctt.cfg && sed -i '/GithubUser=/cGithubUser=lctt' ./lctt-scripts/lctt.cfg
COPY starter.sh .
RUN mkdir TranslateProject 
RUN chown -R lctt:lctt /home/lctt
VOLUME ["/home/lctt/TranslateProject"]
USER lctt
ENTRYPOINT ["/home/lctt/starter.sh"]
CMD ["/bin/bash"]
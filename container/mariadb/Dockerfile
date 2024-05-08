FROM mariadb:11.3.2

COPY init.sh $HOME/mariadb/init/

VOLUME $HOME/mariadb/data:/data

CMD ["/bin/bash", "$HOME/mariadb/init/init.sh"]
#CMD ["tail", "-f", "/dev/null"]

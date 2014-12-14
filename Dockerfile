FROM brimstone/ubuntu:14.04

EXPOSE 8080

CMD []

ENTRYPOINT ["/loader"]

RUN	apt-get update && \
	apt -y install zsh git && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists


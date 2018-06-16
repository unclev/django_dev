FROM python:3.4
ARG PROJECTNAME
ARG WUID
ARG WGID
ENV PYTHONUNBUFFERED=1 \
    WUSER="webdev" WUID=${WUID:-1000} WGID=${WGID:-1000} \
    PROJECTNAME=${PROJECTNAME:-project}
RUN groupadd -g $WGID $WUSER && useradd -m -g $WGID -u $WUID -s /bin/bash $WUSER
WORKDIR "/home/$WUSER"
COPY requirements.txt start.sh ./
RUN pip install --upgrade -r requirements.txt
COPY . ./
RUN chown -Rv $WUSER:$WUSER .
USER $WUSER
ENTRYPOINT ["./start.sh"]


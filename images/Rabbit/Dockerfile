
FROM rabbitmq:3.7-management

COPY rabbitmq.conf /etc/rabbitmq
#COPY definitions.json /etc/rabbitmq
COPY rabbit_4d2655655fd9_2023-12-17.json /etc/rabbitmq/definitions.json
#rabbit_4d2655655fd9_2023-12-17.json

RUN cat /etc/rabbitmq/rabbitmq.conf
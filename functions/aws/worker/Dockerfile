ARG base_image=root_aws_lambda:latest
FROM ${base_image}

ADD https://raw.githubusercontent.com/wlloyduw/SAAF/master/python_template/src/Inspector.py Inspector.py

COPY lambda.py lambda.py
COPY monitor.py monitor.py
RUN chmod 777 Inspector.py lambda.py monitor.py

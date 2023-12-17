FROM root_aws_lambda:latest

ADD --chmod=767 https://raw.githubusercontent.com/wlloyduw/SAAF/master/python_template/src/Inspector.py Inspector.py

COPY --chmod=777 lambda.py lambda.py
COPY --chmod=777 monitor.py monitor.py

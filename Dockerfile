FROM runtimeverificationinc/kontrol:ubuntu-jammy-0.1.344

COPY . /home/user/workshop

USER root
RUN chown -R user:user /home/user
USER user

WORKDIR /home/user/workshop

RUN ./run-kontrol.sh

ENTRYPOINT ["/bin/bash"]

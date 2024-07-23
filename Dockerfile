FROM runtimeverificationinc/kontrol:ubuntu-jammy-0.1.369

COPY . /home/user/workshop

USER root
RUN chown -R user:user /home/user
USER user

WORKDIR /home/user/workshop

RUN ./run-kontrol.sh

ENTRYPOINT ["/bin/bash"]

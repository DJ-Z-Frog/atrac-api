FROM python:3.11-slim AS builder
WORKDIR /root
ENV ARCH=x86_64
RUN apt-get update && apt-get install -y yasm nasm git curl lbzip2 build-essential
RUN git clone https://github.com/acoustid/ffmpeg-build.git
RUN echo "FFMPEG_CONFIGURE_FLAGS+=(--enable-encoder=pcm_s16le --enable-muxer=wav --enable-filter=loudnorm --enable-filter=aresample --enable-filter=replaygain --enable-filter=volume)" >> ffmpeg-build/common.sh
RUN ffmpeg-build/build-linux.sh
RUN mv ffmpeg-build/artifacts/ffmpeg-*-linux-gnu/bin/ffmpeg .

FROM python:3.11-slim

ENV LOG_LEVEL=
COPY --from=builder /root/ffmpeg /usr/bin/ffmpeg

COPY at3tool /usr/bin/at3tool
COPY libatrac.so.1.2.0 /usr/local/lib/libatrac.so.1.2.0
RUN ldconfig
RUN ln -s /usr/local/lib/libatrac.so.1 /usr/local/lib/libatrac.so
RUN dpkg --add-architecture i386
RUN apt update
RUN apt-get -y install libc6:i386 libstdc++6:i386 

COPY requirements.txt .
RUN pip install -r requirements.txt
RUN mkdir /uploads
COPY *.py ./

EXPOSE 5000
ENTRYPOINT ["uvicorn"]
CMD ["main:api", "--host", "0.0.0.0", "--port", "5000"]

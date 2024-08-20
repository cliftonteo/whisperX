FROM nvidia/cuda:11.7.1-cudnn8-runtime-ubuntu20.04

# Set environment variables
ENV PATH /usr/bin:$PATH
ENV LANG C.UTF-8

# Configure the system timezone to Singapore
ENV TZ 'Asia/Singapore'
RUN echo $TZ > /etc/timezone && \
    apt-get update && apt-get install -y tzdata && \
    rm /etc/localtime && \
    ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata && \
    apt-get clean

# Update and install system dependencies
RUN apt-get update && apt-get install -y \
   build-essential \
   zlib1g-dev \
   libncurses5-dev \
   libgdbm-dev \
   libnss3-dev \
   libssl-dev \
   libreadline-dev \
   libffi-dev \
   libbz2-dev \
   libsqlite3-dev \
   liblzma-dev \
   python3 \
   python3-dev \
   python3-pip \
   python3-virtualenv \
   python3-setuptools \
   cython3 \
   wget \
   rsyslog \
   vim \
   git \
   ffmpeg \
   net-tools

# Download and install Python 3.10
RUN wget https://www.python.org/ftp/python/3.10.0/Python-3.10.0.tar.xz
RUN tar xvf Python-3.10.0.tar.xz
RUN cd Python-3.10.0 \
   && ./configure --enable-optimizations \
   && make -j 8 \
   && make altinstall

# Update pip and setuptools
RUN pip3.10 install --upgrade pip setuptools

# Set Python 3.10 as the default
RUN ln -sf /usr/local/bin/python3.10 /usr/bin/python
RUN ln -sf /usr/local/bin/pip3.10 /usr/bin/pip

#install pytorch for gpu use 
RUN pip3.10 install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118

RUN apt-get update && apt-get install -y git

#clone forked repo (to preserve version since repo is active)
RUN pip3.10 install git+https://github.com/racheltlw/whisperx.git

RUN apt install ffmpeg -y

#copy whisperx requirements.txt
COPY build/. /opt/app

WORKDIR /opt/app

RUN pip install -r requirements_transcribe.txt
RUN pip install -r requirements_evaluate.txt

RUN pip3.10 install faster-whisper==0.10.1
RUN pip3.10 install transformers -U
RUN pip3.10 install pyannote-audio==3.3.1
#copy current
COPY ../src/. /opt/app

# clean and clear disk space
RUN rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

# ENTRYPOINT
# change to relevant helper script if only running transcription or evaluation 
ENTRYPOINT ["python", "srs_main_module.py"]

#for testing 
#ENTRYPOINT ["tail", "-f", "/dev/null"]


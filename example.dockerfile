## BUILD FROM jupyter and tensorflow dockerfiles 

# https://github.com/jupyter/docker-stacks/blob/master/base-notebook/Dockerfile 
# https://github.com/tensorflow/tensorflow/blob/master/tensorflow/tools/dockerfiles/dockerfiles/nvidia-jupyter.Dockerfile

#FROM nvidia/cuda:10.0-base-ubuntu18.04
#FROM nvidia/cuda:10.2-base-ubuntu18.04
FROM nvcr.io/nvidia/cuda:10.0-runtime-ubuntu18.04
#FROM nvcr.io/nvidia/cuda:10.2-runtime-ubuntu18.04 # not working this pc.

ARG NB_USER=DEFAULT_USERNAME
ARG NB_UID=DEFAULT_UID
ARG NB_GID=DEFAULT_GID

RUN echo $NB_USER

ADD bin/fix-permissions /usr/local/bin/fix-permissions

ENV JUPYTER_ENABLE_LAB true
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility
ENV NVIDIA_VISIBLE_DEVICES=all

USER root

# Install all OS dependencies for notebook server that starts but lacks all
# features (e.g., download as all possible file formats)
ENV DEBIAN_FRONTEND noninteractive

# See http://bugs.python.org/issue19846
ENV LANG C.UTF-8
RUN apt-get update && apt-get -yq dist-upgrade \
 && apt-get install -yq --no-install-recommends \
    apt-utils

RUN apt-get install -yq --no-install-recommends \
    wget \
    bzip2 \
    ca-certificates \
    sudo \
    locales \
    fonts-liberation \
    build-essential \
    libfreetype6-dev \
    libhdf5-serial-dev \
    libpng-dev \
    libzmq3-dev \
    pkg-config \
    software-properties-common \
    unzip

# Pick up some TF dependencies
RUN apt-get install -yq --no-install-recommends \
    cuda-command-line-tools-10-0 \
    cuda-cublas-10-0 \
	cuda-cufft-10-0 \
	cuda-cufft-dev-10-0 \
    cuda-curand-10-0 \
    cuda-cusolver-10-0 \
    cuda-cusparse-10-0

RUN apt-get install -yq --no-install-recommends \
	cuda-curand-dev-10-0 \
    cuda-npp-dev-10-0

#RUN apt-get install -yq --no-install-recommends \
#    libcudnn7-dev \
    #libcudnn7=7.6.5.32-1+cuda10.2 \
    #libnccl2=2.5.6-1+cuda10.2

RUN apt-get clean && \
   rm -rf /var/lib/apt/lists/*

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen

RUN apt-get update && \
    apt-get install -y nvinfer-runtime-trt-repo-ubuntu1804-5.0.2-ga-cuda10.0 && \
    apt-get update && \
    apt-get install -y libnvinfer6=6.0.1-1+cuda10.0

#ARG PYTHON=python3
#ARG PIP=pip3
#
#RUN apt-get update && apt-get install -y \
#    ${PYTHON} \
#    ${PYTHON}-pip

# Configure environment
ENV CONDA_DIR=/opt/conda \
    SHELL=/bin/bash \
    NB_USER=$NB_USER \
    NB_UID=$NB_UID \
    NB_GID=$NB_GID \
    LC_ALL=en_US.UTF-8 \
    LANG=en_US.UTF-8 \
    LANGUAGE=en_US.UTF-8
ENV PATH=$CONDA_DIR/bin:$PATH \
    HOME=/home/$NB_USER

# Create jovyan user with UID=1000 and in the 'users' group
# and make sure these dirs are writable by the `users` group.
RUN groupadd wheel -g 11 && \
    echo "auth required pam_wheel.so use_uid" >> /etc/pam.d/su && \
    useradd -m -s /bin/bash -N -u $NB_UID $NB_USER && \
    mkdir -p $CONDA_DIR && \
    chown $NB_USER:$NB_GID $CONDA_DIR && \
    chmod g+w /etc/passwd && \
    fix-permissions $HOME && \
    fix-permissions $CONDA_DIR

# Setup work directory for backward-compatibility
RUN mkdir /home/$NB_USER/test && \
    mkdir /home/$NB_USER/.keras

COPY test-notebooks /home/$NB_USER/test
COPY config/keras.json /home/$NB_USER/.keras/
COPY config/theanorc /home/$NB_USER/.theanorc

USER $NB_UID


#RUN ${PIP} install --upgrade \
#    pip \
#    tensorflow-gpu \
#    setuptools

# Install conda as jovyan and check the md5 sum provided on the download site
ENV MINICONDA_VERSION 4.7.12.1
RUN cd /tmp && \
    wget --quiet https://repo.continuum.io/miniconda/Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    echo "81c773ff87af5cfac79ab862942ab6b3 *Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh" | md5sum -c - && \
    /bin/bash Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh -f -b -p $CONDA_DIR && \
    rm Miniconda3-${MINICONDA_VERSION}-Linux-x86_64.sh && \
    $CONDA_DIR/bin/conda config --system --prepend channels conda-forge && \
    $CONDA_DIR/bin/conda config --system --set auto_update_conda false && \
    $CONDA_DIR/bin/conda config --system --set show_channel_urls true && \
    $CONDA_DIR/bin/conda install --quiet --yes conda="${MINICONDA_VERSION%.*}.*" && \
    $CONDA_DIR/bin/conda update --all --quiet --yes && \
    conda clean -tipsy && \
    rm -rf /home/$NB_USER/.cache/yarn

RUN conda update -yq -n base conda

# Install Tini
RUN conda install --quiet --yes 'tini=0.18.0' && \
    conda list tini | grep tini | tr -s ' ' | cut -d ' ' -f 1,2 >> $CONDA_DIR/conda-meta/pinned && \
    conda clean -tipsy

# Install Jupyter Notebook, Lab, and Hub
# Generate a notebook server config
# Cleanup temporary files
# Correct permissions
# Do all this in a single RUN command to avoid duplicating all of the
# files across image layers when the permissions change
COPY requirements.txt .

RUN conda install --quiet --yes \
    'notebook=6.0.2' \
    'jupyterhub=1.0.0' \
    'jupyterlab=1.2.4'

#jupyter labextension install @jupyterlab/hub-extension@^0.19.1 && \
RUN conda install --quiet --yes --file requirements.txt
RUN conda clean -tipsy && \
    npm cache clean --force && \
    jupyter notebook --generate-config && \
    rm -rf $CONDA_DIR/share/jupyter/lab/staging && \
    rm -rf /home/$NB_USER/.cache/yarn

USER root

RUN fix-permissions /home/$NB_USER && \
    fix-permissions $CONDA_DIR && \
    fix-permissions /home/$NB_USER/.keras && \
    fix-permissions /home/$NB_USER/.theanorc 
#    fix-permissions /home/$NB_USER/notebooks

RUN jupyter-nbextension enable tree-filter/index && \
    jupyter-nbextension enable code_prettify/code_prettify && \
    jupyter-nbextension enable help_panel/help_panel && \
    jupyter-nbextension enable highlight_selected_word/main --highlight_selected_word.use_toggle_hotkey=true && \
    jupyter-nbextension enable autosavetime/main && \
    jupyter-nbextension enable livemdpreview/livemdpreview && \
    jupyter-nbextension enable printview/main && \
    jupyter-nbextension enable code_prettify/2to3 && \
    jupyter-nbextension enable execute_time/ExecuteTime && \
    jupyter-nbextension enable highlighter/highlighter && \
    jupyter-nbextension enable python-markdown/main && \
    jupyter-nbextension enable codefolding/main && \
    jupyter-nbextension enable codefolding/edit && \
    jupyter-nbextension enable toc2/main && \
    jupyter-nbextension enable init_cell/main && \
    jupyter-nbextension enable navigation-hotkeys/main && \
    jupyter-nbextension enable rubberband/main && \
    jupyter-nbextension enable scroll_down/main && \
    jupyter-nbextension enable notify/notify && \
    jupyter-nbextension enable ruler/main && \
    jupyter-nbextension enable select_keymap/main && \
    jupyter-nbextension enable varInspector/main && \
    jupyter-nbextension enable code_font_size/code_font_size && \
    jupyter-nbextension enable hinterland/hinterland && \
    jupyter-nbextension enable move_selected_cells/main && \
    jupyter-nbextension enable scratchpad/main 

# Add local files as late as possible to avoid cache busting
COPY bin/start.sh /usr/local/bin/
COPY bin/start-notebook.sh /usr/local/bin/
COPY bin/start-singleuser.sh /usr/local/bin/
RUN mkdir -p /etc/jupyter/

RUN fix-permissions /etc/jupyter/
RUN apt-get install -y --no-install-recommends libgl1-mesa-glx 
RUN apt-get install -y --no-install-recommends curl
RUN conda install -yc conda-forge numpy pip
RUN apt-get install -y libcublas-dev
RUN apt-get install -y libcudnn7-dev
RUN pip install pycuda==2019.1.2


RUN apt-get install -y --no-install-recommends ocl-icd-opencl-dev ocl-icd-libopencl1 
RUN pip install pyopencl
RUN mkdir -p /etc/OpenCL/vendors &&  echo "libnvidia-opencl.so.1" > /etc/OpenCL/vendors/nvidia.icd

ENV PATH="/usr/local/cuda-10.0/bin/:${PATH}"

RUN apt install -y cmake pkg-config libavcodec-dev libavformat-dev libswscale-dev --no-install-recommends

RUN apt install -y lshw
RUN apt lshw -class processor | grep capabilities | sed -E 's/^\s+capabilities:\s//'


######## UNCOMMENT BELOW TO BUILD ##########
######## IT WILL TAKE A LONG TIME ##########
########       BELIEVE  ME        ##########
########                          ##########
########   YOU HAVE BEEN WARNED   ##########
#
#
#  RUN cd /tmp/ && wget -qO- https://github.com/opencv/opencv/archive/4.1.2.tar.gz         | tar --transform 's/^dbt2-0.37.50.3/dbt2/' -xz
#  RUN cd /tmp/ && wget -qO- https://github.com/opencv/opencv_contrib/archive/4.1.2.tar.gz | tar --transform 's/^dbt2-0.37.50.3/dbt2/' -xz
#  NEW RUN mkdir /tmp/opencv-4.1.2/build && cd /tmp/opencv-4.1.2/build && cmake -D CMAKE_BUILD_TYPE=RELEASE -D CMAKE_INSTALL_PREFIX=/usr/local -D WITH_CUDA=ON -D WITH_OPENCL=ON -D ENABLE_FAST_MATH=1 -D CUDA_FAST_MATH=1 -D WITH_CUBLAS=1 -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-4.1.2/modules -D WITH_LIBV4L=OFF -D WITH_V4L=OFF -D INSTALL_C_EXAMPLES=OFF -D WITH_DC1394=OFF -D ENABLE_NEON=OFF -D OPENCV_ENABLE_NONFREE=ON  -D WITH_PROTOBUF=OFF -D INSTALL_PYTHON_EXAMPLES=ON -D BUILD_OPENCV_PYTHON3=yes  -D PYTHON3_EXECUTABLE=$(which python3) -D PYTHON_INCLUDE_DIR=$(python3 -c "from distutils.sysconfig import get_python_inc; print(get_python_inc())") -D PYTHON_INCLUDE_DIR2=$(python3 -c "from os.path import dirname; from distutils.sysconfig import get_config_h_filename; print(dirname(get_config_h_filename()))") -D PYTHON_LIBRARY=$(python3 -c "from distutils.sysconfig import get_config_var;from os.path import dirname,join ; print(join(dirname(get_config_var('LIBPC')),get_config_var('LDLIBRARY')))") -D PYTHON3_NUMPY_INCLUDE_DIRS=$(python3 -c "import numpy; print(numpy.get_include())") -D PYTHON3_PACKAGES_PATH=$(python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())")  .. && make -j$(cat /proc/cpuinfo | grep processor | wc -l)  && make -j$(cat /proc/cpuinfo | grep processor | wc -l) install
##RUN rm -rfv /tmp/*

##### USING FILES BUILT ON MY HOST MACHINE #######

COPY assets/cv.tar.gz /tmp/
RUN cd /tmp && tar -xvf /tmp/cv.tar.gz && rm /tmp/cv.tar.gz && cd /tmp/cv/opencv-4.1.2/build && make -j6 install
##############################
COPY config/jupyterhub_config.py /etc/jupyter/jupyterhub_config.py
COPY config/environment.yaml /etc/jupyter/environment.yaml

RUN apt install -y vim git silversearcher-ag
RUN apt install -y libsm6 libxext6 libxrender-dev
#RUN pip install opencv-python==4.1.2.30

RUN chown -Rv $NB_USER /home/$NB_USER
RUN chgrp -Rv $NB_GID /home/$NB_USER

# Switch back to jovyan to avoid accidental container runs as root
USER $NB_UID

RUN mkdir $HOME/notebooks

EXPOSE 8888
WORKDIR $HOME

# Configure container startup
ENTRYPOINT ["tini", "-g", "--"]
CMD ["start-notebook.sh"]


# VOLUME /home/$NB_USER/notebooks


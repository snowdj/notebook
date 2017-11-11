# jupyter project recommends pinning the base image: https://github.com/jupyter/docker-stacks#other-tips-and-known-issues
FROM jupyter/scipy-notebook:da2c5a4d00fa

# jupyter project recently removed support for python2, we'll recreate it using their commit as a guide
# https://github.com/jupyter/docker-stacks/commit/32b3d2bec23bc46fab1ed324f04a0ad7a7c73747#commitcomment-24129620

# Install Python 2 packages
RUN conda create --quiet --yes -p $CONDA_DIR/envs/python2 python=2.7 \
    'beautifulsoup4=4.5.*' \
    'bokeh=0.12*' \
    'cloudpickle=0.2*' \
    'cython=0.25*' \
    'dill=0.2*' \
    'h5py=2.7*' \
    'hdf5=1.10.1' \
    'ipython=5.3*' \
    'ipywidgets=6.0*' \
    'matplotlib=1.4.*' \
    'nomkl' \
    'numba=0.13*' \
    'numexpr=2.6*' \
    'numpy=1.8.*' \
    'pandas=0.14*' \
    'patsy=0.4*' \
    'pyzmq' \
    'scikit-image=0.10*' \
    'scikit-learn=0.15*' \
    'scipy=0.14*' \
    'seaborn=0.7*' \
    'six=1.10.*' \
    'sqlalchemy=1.1*' \
    'statsmodels=0.5.*' \
    'sympy=1.0*' \
    'vincent=0.4.*' \
    'xlrd'
# Add shortcuts to distinguish pip for python2 and python3 envs
RUN ln -s $CONDA_DIR/envs/python2/bin/pip $CONDA_DIR/bin/pip2 && \
    ln -s $CONDA_DIR/bin/pip $CONDA_DIR/bin/pip3

# Import matplotlib the first time to build the font cache.
ENV XDG_CACHE_HOME /home/$NB_USER/.cache/
ENV MPLBACKEND Agg
RUN $CONDA_DIR/envs/python2/bin/python -c "import matplotlib.pyplot"

USER root

# Install Python 2 kernel spec globally to avoid permission problems when NB_UID
# switching at runtime and to allow the notebook server running out of the root
# environment to find it. Also, activate the python2 environment upon kernel
# launch.
RUN pip install kernda --no-cache && \
    $CONDA_DIR/envs/python2/bin/python -m ipykernel install && \
    kernda -o -y /usr/local/share/jupyter/kernels/python2/kernel.json && \
    pip uninstall kernda -y

USER $NB_USER

# install the probcomp libraries
RUN conda install -n python2 --quiet --yes -c probcomp/label/dev \
    'bayeslite=0.3.2rc6' \
    'cgpm=0.1.1rc5' \
    'crosscat=0.1.57rc5' \
    'iventure=0.2.1rc7' \
    'venture=0.5.2rc4'

# Remove pyqt and qt pulled in for matplotlib since we're only ever going to
# use notebook-friendly backends in these images
## this is broken with conda matplotlib 1.4.*, fixed in matplotlib >= 1.5.* anaconda package
## see: https://github.com/ContinuumIO/anaconda-issues/issues/1068
##RUN conda remove -n python2 --quiet --yes --force qt pyqt
RUN conda clean -tipsy

# uncomment this to use plain-vanilla apsw (we can't use conda to install because there isn't an old enough version available)
RUN bash -c 'source activate python2 && pip install apsw'

ENV CONTENT_URL probcomp-oreilly20170627.s3.amazonaws.com/content-package.tgz
COPY docker-entrypoint.sh /usr/bin

ENTRYPOINT      ["docker-entrypoint.sh"]
CMD             ["start-notebook.sh"]

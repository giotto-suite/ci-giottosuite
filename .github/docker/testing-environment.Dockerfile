FROM rocker/r-ver:4.6.0

# Install minimal system dependencies for pak
RUN apt-get update && apt-get install -y \
    software-properties-common \
    curl \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    libglpk-dev \
    pandoc \
    python3-pip \
    git \
    libzstd-dev \
    liblz4-dev \
    libsnappy-dev \
    libbz2-dev \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install R packages using pak
RUN R -e "install.packages('pak', repos = 'https://r-lib.github.io/p/pak/stable/'); \
    pak::pkg_install(c( \
    'assertthat', \
    'bit64', \
    'checkmate', \
    'colorRamp2', \
    'covr', \
    'cowplot', \
    'data.table', \
    'dbscan', \
    'deldir', \
    'devtools', \
    'DT', \
    'exactextractr', \
    'FNN', \
    'future', \
    'future.apply', \
    'geometry', \
    'ggalluvial', \
    'ggdendro', \
    'ggforce', \
    'ggraph', \
    'ggplot2', \
    'ggrepel', \
    'glue', \
    'gtools', \
    'htmltools', \
    'htmlwidgets', \
    'igraph', \
    'jsonlite', \
    'lintr', \
    'knitr', \
    'lifecycle', \
    'magick', \
    'magrittr', \
    'matrixStats', \
    'methods', \
    'networkD3', \
    'parallel', \
    'purrr', \
    'plotly', \
    'png', \
    'progressr', \
    'qpdf', \
    'qs', \
    'R.utils', \
    'R6', \
    'raster', \
    'rcmdcheck', \
    'RColorBrewer', \
    'reshape2', \
    'reticulate', \
    'remotes', \
    'rgl', \
    'rlang', \
    'rmarkdown', \
    'RTriangle', \
    'scales', \
    'scattermore', \
    'scatterpie', \
    'scran', \
    'Seurat', \
    'SeuratObject', \
    'sf', \
    'sp', \
    'spdep', \
    'stats', \
    'stars', \
    'terra', \
    'testthat', \
    'tidyselect', \
    'tiff', \
    'uwot', \
    'vctrs', \
    'viridis', \
    'viridisLite', \
    'xml2' \
    ))" && \
    R -e "pak::pkg_install(c( \
    'bioc::Biobase', \
    'bioc::BiocParallel', \
    'bioc::BiocCheck', \
    'bioc::BiocStyle', \
    'bioc::BiocSingular', \
    'bioc::chihaya', \
    'bioc::ComplexHeatmap', \
    'bioc::DelayedArray', \
    'bioc::DelayedMatrixStats', \
    'bioc::HDF5Array', \
    'bioc::MatrixGenerics', \
    'bioc::rhdf5', \
    'bioc::S4Vectors', \
    'bioc::ScaledMatrix', \
    'bioc::SingleCellExperiment', \
    'bioc::sparseMatrixStats', \
    'bioc::SpatialExperiment', \
    'bioc::STexampleData', \
    'bioc::SummarizedExperiment' \
    ))" && \
    R -e "Sys.setenv(ARROW_WITH_ZSTD = 'ON'); \
    Sys.setenv(ARROW_WITH_GZ2 = 'ON'); \
    Sys.setenv(ARROW_WITH_BZ2 = 'ON'); \
    Sys.setenv(ARROW_WITH_LZ4 = 'ON'); \
    Sys.setenv(ARROW_WITH_SNAPPY = 'ON'); \
    install.packages('arrow', repos = c('https://apache.r-universe.dev'), type = 'source')" && \
    rm -rf /tmp/downloaded_packages/

# Validate package installation
RUN echo "Validating dependencies..." && \
    R -e 'packages <- c("sf", "stars", "raster", "sp", "terra", "Matrix", "igraph", "arrow"); \
    load_res <- vapply(packages, function(pkg) { \
        load_fail <- !requireNamespace(pkg, quietly = TRUE); \
        if (load_fail) { \
            message(paste("Package", pkg, "failed to load")); \
            TRUE; \
        } else { \
            message(paste("✓", pkg, "loaded successfully")); \
            FALSE; \
        } \
    }, FUN.VALUE = logical(1L)); \
    if (any(load_res)) stop("some package(s) did not install correctly"); \
    message("Checking sf capabilities:"); \
    print(sf::sf_extSoftVersion()); \
    message("All spatial validation checks passed!");'

# Setup Python environment and clean up
ENV RETICULATE_MINICONDA_PATH=/opt/miniconda

# Install Miniforge (ToS-free, conda-forge only) and symlink to /opt/miniconda
RUN curl -L -O "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" && \
    bash Miniforge3-Linux-x86_64.sh -b -p /opt/miniforge && \
    rm Miniforge3-Linux-x86_64.sh && \
    ln -s /opt/miniforge /opt/miniconda && \
    /opt/miniforge/bin/conda config --set channel_priority strict

# Create Python environments and install packages
RUN R -e "reticulate::conda_create(envname = 'giotto_env', python_version = '3.10.2')" && \
    R -e "reticulate::conda_install(packages = 'scipy', envname = 'r-reticulate')" && \
    R -e "reticulate::conda_install(packages = c( \
    'scipy', \
    'pandas=1.5.1', \
    'networkx=2.8.8', \
    'python-igraph=0.10.2', \
    'leidenalg=0.9.0', \
    'scikit-learn=1.1.3' \
    ), envname = 'giotto_env')" && \
    R -e "reticulate::conda_install(packages = c( \
    'python-louvain==0.16', \
    'smfishhmrf', \
    'session-info', \
    'scanpy', \
    'scrublet' \
    ), envname = 'giotto_env', pip = TRUE)" && \
    /opt/miniforge/bin/conda clean -afy && \
    rm -rf /opt/miniforge/pkgs/*

WORKDIR /package
CMD ["R"]

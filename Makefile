all: pytorch python entrypoint
.PHONY: pytorch python entrypoint

REPO := yoshum

UBUNTU_VERSION ?= 18.04
PYTHON_VERSION ?= 3.6
CUDA_VERSION ?= 10.1

ifeq ($(PYTHON_VERSION),3.6)
PYTHON_REVISION = 3.6.9
GPG_KEY = 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
endif

MKL ?= 1
ifeq ($(MKL),1)
PIP_PACKAGES = intel-scikit-learn intel-scipy intel-numpy pillow==6.2.2
TAG = $(TAG_BASE)
else
PIP_PACKAGES = scikit-learn scipy numpy pillow==6.2.2
TAG = $(TAG_BASE)-nomkl
endif

define build-image
	cd $1 ; \
	docker build -t $(REPO)/$1:$2 $3 .
endef
define copy-resources
	mkdir -p $2/resources/$1
	cp -r $1/resources/* $2/resources/$1
endef

TORCH_VERSION ?= latest
ifeq ($(TORCH_VERSION),latest)
TORCH_PACKAGES = torch torchvision
endif

ifeq ($(TORCH_VERSION),1.4)
ifeq ($(CUDA_VERSION),10.1)
TORCH_PACKAGES = torch==1.4.0 torchvision==0.5.0
endif
ifeq ($(CUDA_VERSION),10.0)
TORCH_PACKAGES = torch==1.4.0+cu100 torchvision==0.5.0+cu100 -f https://download.pytorch.org/whl/torch_stable.html
endif
endif

ifeq ($(TORCH_VERSION),1.3)
ifeq ($(CUDA_VERSION),10.1)
TORCH_PACKAGES = torch==1.3.1 torchvision==0.4.2
endif
ifeq ($(CUDA_VERSION),10.0)
TORCH_PACKAGES = torch==1.3.1+cu100 torchvision==0.4.2+cu100 -f https://download.pytorch.org/whl/torch_stable.html
endif
endif

pytorch: TAG_BASE = $(TORCH_VERSION)-py$(PYTHON_VERSION)-cuda$(CUDA_VERSION)-ubuntu$(UBUNTU_VERSION)
pytorch:
	$(call copy-resources,entrypoint,pytorch)
	$(call build-image,pytorch,$(TAG),\
		--build-arg PYTHON_VERSION=$(PYTHON_REVISION) \
		--build-arg CUDA_IMAGE_VERSION=$(CUDA_VERSION) \
		--build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) \
		--build-arg GPG_KEY=$(GPG_KEY) \
		--build-arg TORCH_PACKAGES="$(TORCH_PACKAGES)" \
		--build-arg PIP_PACKAGES="$(PIP_PACKAGES)")
	rm -rf pytorch/resources/entrypoint

pytorch-all-versions:
	make pytorch TORCH_VERSION=latest
	make pytorch TORCH_VERSION=1.4
	make pytorch TORCH_VERSION=1.3
	make pytorch TORCH_VERSION=latest MKL=0
	make pytorch TORCH_VERSION=1.4 MKL=0
	make pytorch TORCH_VERSION=1.3 MKL=0

python:
	$(call copy-resources,entrypoint,python)
	$(call build-image,python,$(PYTHON_VERSION)-ubuntu$(UBUNTU_VERSION),\
		--build-arg PYTHON_VERSION=$(PYTHON_REVISION) \
		--build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) \
		--build-arg GPG_KEY=$(GPG_KEY))
	rm -rf python/resources/entrypoint

entrypoint:
	$(call build-image,entrypoint,$(UBUNTU_VERSION),)

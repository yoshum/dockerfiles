all: pytorch python entrypoint
.PHONY: pytorch python entrypoint

REPO := yoshum

UBUNTU_VERSION ?= 18.04
PYTHON_VERSION ?= 3.6
CUDA_VERSION ?= 10.0

ifeq ($(PYTHON_VERSION),3.6)
PYTHON_REVISION = 3.6.9
GPG_KEY = 0D96DF4D4110E5C43FBFB17F2D347EA6AA65421D
endif

MKL ?= 1
ifeq ($(MKL),1)
PIP_PACKAGES = intel-scikit-learn intel-scipy intel-numpy
TAG = $(TAG_BASE)
else
PIP_PACKAGES = scikit-learn scipy numpy
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

python:
	$(call copy-resources,entrypoint,python)
	$(call build-image,\
		python,\
		$(PYTHON_VERSION)-ubuntu$(UBUNTU_VERSION),\
		--build-arg PYTHON_VERSION=$(PYTHON_REVISION) \
		--build-arg UBUNTU_VERSION=$(UBUNTU_VERSION) \
		--build-arg GPG_KEY=$(GPG_KEY))
	rm -rf python/resources/entrypoint

entrypoint:
	$(call build-image,entrypoint,$(UBUNTU_VERSION),)

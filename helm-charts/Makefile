HELM := helm
ROOT_DIR := $(shell dirname $(realpath $(lastword $(MAKEFILE_LIST))))
PACKAGE_DIR := $(ROOT_DIR)/dist

BASE_CHARTS := keycloak mongodb mongo-express
BUILD_BASE_CHARTS := $(foreach chart, $(BASE_CHARTS), build-$(chart))

HELM_CHARTS := controller
SUB_CHARTS := $(wildcard controller/components/*)
BUILD_HELM_CHARTS := $(foreach chart, $(HELM_CHARTS), build-$(chart))

.phony: all

all: $(BUILD_BASE_CHARTS) build-sub-charts $(BUILD_HELM_CHARTS)

.ONESHELL:
build-%: init-% lint-%
	@echo "========================================="
	@echo "      helm pack	$*     "
	@echo "========================================="
	@mkdir -p $(PACKAGE_DIR)
	if [ -f $*/Chart.yaml ]
	then
		$(HELM) package -d $(PACKAGE_DIR) $*
		$(HELM) repo index $(PACKAGE_DIR)
	fi

lint-%:
	@echo "===================================="
	@echo "      helm lint	$*     "
	@echo "===================================="
	if [ -f $*/Chart.yaml ]; then $(HELM) lint $*; fi

init-%:
	@echo "============================================="
	@echo " helm dependency update	$* "
	@echo "============================================="
	if [ -f $*/Chart.yaml ]; then $(HELM) dep up $*; fi

build-sub-charts:
	@for chart in $(SUB_CHARTS); do \
		if [ -f $$chart/Chart.yaml ]; then $(HELM) dep up $$chart; fi
		if [ -f $$chart/Chart.yaml ]; then $(HELM) lint $$chart; fi
	done

clean-sub-charts:
	@for chart in $(SUB_CHARTS); do \
		rm -rf $$chart/charts; \
		rm -rf $$chart/*.lock; \
	done

clean: clean-sub-charts
	rm -rf dist
	rm -rf */charts
	rm -rf */*.lock

name 'kubernetes'
run_list 'kube_test'

default_source :supermarket

cookbook 'kube', path: './'
cookbook 'kube_test', path: 'test/cookbooks/kube_test'

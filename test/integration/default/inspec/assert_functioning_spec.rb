############################
# recipe[kube_test::default]
############################

# kube-apiserver
describe service('kube-apiserver') do
  it { should be_installed }
  it { should be_running }
end

describe port(8080) do
  it { should be_listening }
  its('processes') { should include 'kube-apiserver' }
end

describe port(6443) do
  it { should be_listening }
  its('processes') { should include 'kube-apiserver' }
end

# kube-controller-manager
describe service('kube-controller-manager') do
  it { should be_installed }
  it { should be_running }
end

# kube-proxy
describe service('kube-proxy') do
  it { should be_installed }
  it { should be_running }
end

# kube-scheduler
describe service('kube-scheduler') do
  it { should be_installed }
  it { should be_running }
end

# kubelet
describe service('kubelet') do
  it { should be_installed }
  it { should be_running }
end

describe port(10_250) do
  it { should be_listening }
  its('processes') { should include 'kubelet' }
end

# kubectl
describe command('kubectl get node') do
  its('exit_status') { is_expected.to eq 0 }
  its('stdout') { is_expected.to match(/default.*Ready/) }
end

# busybox pod
describe command('kubectl get pod busybox') do
  its('exit_status') { is_expected.to eq 0 }
  its('stdout') { is_expected.to match(/busybox.*Running/) }
end

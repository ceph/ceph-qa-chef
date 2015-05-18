Teuthology currently uses Chef to do some node configurations, but we're
transitioning away from Chef in order to use Ansible. This work is in progress
at https://github.com/ceph/ceph-cm-ansible 

We want to remove some of the hardcoded values that are unique to our labs,
like the "ubuntu" UID and the URL to gitbuilder.ceph.com.

We've ported a lot of the Chef settings, but we're not yet complete.

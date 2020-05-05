- name: Clone myuserprefs on the remote
  git:
    repo: 'https://github.com/flmmartins/myusersetup.git'
    dest: /home/vagrant/myusersetup

# This copies the specified file from the remote to the current dir
- name: Fetch yml from remote
  fetch:
    src: /tmp/B/Y.yml
    dest: ./
    flat: yes

- name: Run Y
  include_tasks: Y.yml
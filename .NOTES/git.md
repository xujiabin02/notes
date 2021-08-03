

# delele remote branch

```sh
git push origin --delete feature/login
```



# git cherry-pick 教程





```yml
hosts: 'cdp_deploy_composer'
tasks:
  - name: "find {{ gio_pkg_dir }} dirs"
    find:
      file_type: file
      age: 1d
      paths: "{{ gio_pkg_dir }}"
      patterns: 'id-service-*.tar.gz'
    register: artifacts
    become: yes
  - debug:
      msg: "{{ artifacts.files }}"
```


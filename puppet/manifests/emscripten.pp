$emscripten_deps = ["git", "openjdk-6-jdk", "nodejs"]
$clang_version = "3.2"
$clang_dir = "clang+llvm-${clang_version}-x86-linux-ubuntu-12.04"
$clang_filename = "${clang_dir}.tar.gz"
$clang_url = "http://llvm.org/releases/${clang_version}/${clang_filename}"
$emscripten_dir = "emscripten"
$prefix = "/opt"

Exec {
    user => root,
    cwd => "${prefix}/${emscripten_dir}",
    logoutput => on_failure,
    environment => ["PWD=${emscripten_dir}", "HOME=/home/vagrant"],
    timeout => 0
}

class emscripten {
    file { "/home/vagrant/.emscripten":
        owner => vagrant,
        group => vagrant,
        mode => 664,
        source => "/vagrant/puppet/files/dot.emscripten"
    }

    exec { "/usr/bin/apt-get update":
        alias => "apt-get-update",
        cwd => "/root",
        require => Exec["add-nodejs-repo"]
    }

    exec { "/usr/bin/add-apt-repository ppa:richarvey/nodejs":
        alias => "add-nodejs-repo",
        cwd => "/root",
    }

    package {
      $emscripten_deps:
        ensure => "latest",
        require => Exec["apt-get-update"];

      "python-software-properties":
        ensure => "latest";
    }

    exec { "/usr/bin/git clone https://github.com/kripken/emscripten/":
        alias => "git-clone-emscripten",
        cwd => $prefix,
        require => Package[$emscripten_deps],
        creates => "${prefix}/${emscripten_dir}"
    }

    exec { "/usr/bin/git pull origin master":
        alias => "git-pull-emscripten",
        require => Exec["git-clone-emscripten"]
    }

    exec { "/usr/bin/wget ${clang_url}":
        alias => "wget-clang-llvm",
        cwd => $prefix,
        creates => "${prefix}/${clang_filename}",
        environment => ["PWD=${prefix}", "HOME=/home/vagrant"],
    }

    exec { "/bin/tar -zxf ${clang_filename}":
        alias => "untar-clang-llvm",
        cwd => $prefix,
        environment => ["PWD=${prefix}", "HOME=/home/vagrant"],
        creates => "${prefix}/${clang_dir}",
        require => Exec["wget-clang-llvm"]
    }

    file { "/etc/profile.d/emscripten.sh":
        ensure => "file",
        owner => root,
        group => root,
        mode => 755,
        content => "export PATH=\"\$PATH:${prefix}/${emscripten_dir}\"",
        require => Exec["untar-clang-llvm"]
    }

    file { "${prefix}/clang+llvm-latest":
        ensure => "link",
        target => "${prefix}/${clang_dir}";
    }
}

group { "puppet":
  ensure => "present",
}

include emscripten

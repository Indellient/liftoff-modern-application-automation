pkg_name=jenkins
pkg_origin=liftoff-modern-application-delivery
pkg_version=2.190.1
pkg_maintainer="Indellient Devops <devops@indellient.com>"
pkg_description="The leading open source automation server, Jenkins provides hundreds of plugins to support building, deploying and automating any project."
pkg_license=('mit')
pkg_upstream_url="https://jenkins.io/"
pkg_source="http://mirrors.jenkins.io/war-stable/${pkg_version}/jenkins.war"
pkg_shasum="46fb1d25d9423fc66aadd648dc74b9772863a7fbbd89bfc14c873cd0c3436f05"
pkg_deps=(core/jre8 core/curl core/git)
pkg_svc_user="root"

pkg_exports=(
  [port]=jenkins.http.port
)
pkg_exposes=(port)

do_unpack() {
  return 0
}

do_build() {
  return 0
}

do_install() {
  cp "${HAB_CACHE_SRC_PATH}"/"${pkg_filename}" "${pkg_prefix}"/jenkins.war
}

module Kubeclient
  module Common
    # Backward compatibility for old versions where kind is missing (e.g. OpenShift Enterprise 3.1)
    class MissingKindCompatibility
      MAPPING = {
        'bindings'                   => 'Binding',
        'componentstatuses'          => 'ComponentStatus',
        'endpoints'                  => 'Endpoints',
        'events'                     => 'Event',
        'limitranges'                => 'LimitRange',
        'namespaces'                 => 'Namespace',
        'nodes'                      => 'Node',
        'persistentvolumeclaims'     => 'PersistentVolumeClaim',
        'persistentvolumes'          => 'PersistentVolume',
        'pods'                       => 'Pod',
        'podtemplates'               => 'PodTemplate',
        'replicationcontrollers'     => 'ReplicationController',
        'resourcequotas'             => 'ResourceQuota',
        'secrets'                    => 'Secret',
        'securitycontextconstraints' => 'SecurityContextConstraints',
        'serviceaccounts'            => 'ServiceAccount',
        'services'                   => 'Service',
        'buildconfigs'               => 'BuildConfig',
        'builds'                     => 'Build',
        'clusternetworks'            => 'ClusterNetwork',
        'clusterpolicies'            => 'ClusterPolicy',
        'clusterpolicybindings'      => 'ClusterPolicyBinding',
        'clusterrolebindings'        => 'ClusterRoleBinding',
        'clusterroles'               => 'ClusterRole',
        'deploymentconfigrollbacks'  => 'DeploymentConfigRollback',
        'deploymentconfigs'          => 'DeploymentConfig',
        'generatedeploymentconfigs'  => 'DeploymentConfig',
        'groups'                     => 'Group',
        'hostsubnets'                => 'HostSubnet',
        'identities'                 => 'Identity',
        'images'                     => 'Image',
        'imagestreamimages'          => 'ImageStreamImage',
        'imagestreammappings'        => 'ImageStreamMapping',
        'imagestreams'               => 'ImageStream',
        'imagestreamtags'            => 'ImageStreamTag',
        'localresourceaccessreviews' => 'LocalResourceAccessReview',
        'localsubjectaccessreviews'  => 'LocalSubjectAccessReview',
        'netnamespaces'              => 'NetNamespace',
        'oauthaccesstokens'          => 'OAuthAccessToken',
        'oauthauthorizetokens'       => 'OAuthAuthorizeToken',
        'oauthclientauthorizations'  => 'OAuthClientAuthorization',
        'oauthclients'               => 'OAuthClient',
        'policies'                   => 'Policy',
        'policybindings'             => 'PolicyBinding',
        'processedtemplates'         => 'Template',
        'projectrequests'            => 'ProjectRequest',
        'projects'                   => 'Project',
        'resourceaccessreviews'      => 'ResourceAccessReview',
        'rolebindings'               => 'RoleBinding',
        'roles'                      => 'Role',
        'routes'                     => 'Route',
        'subjectaccessreviews'       => 'SubjectAccessReview',
        'templates'                  => 'Template',
        'useridentitymappings'       => 'UserIdentityMapping',
        'users'                      => 'User'
      }.freeze

      def self.resource_kind(name)
        MAPPING[name]
      end
    end
  end
end

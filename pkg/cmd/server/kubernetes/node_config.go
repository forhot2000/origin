package kubernetes

import (
	"crypto/x509"
	"fmt"
	"net"

	"github.com/GoogleCloudPlatform/kubernetes/pkg/client"
	"github.com/GoogleCloudPlatform/kubernetes/pkg/kubelet/dockertools"
	"github.com/golang/glog"

	configapi "github.com/openshift/origin/pkg/cmd/server/api"
	"github.com/openshift/origin/pkg/cmd/util"
	"github.com/openshift/origin/pkg/cmd/util/variable"
)

// NodeConfig represents the required parameters to start the OpenShift node
// through Kubernetes. All fields are required.
type NodeConfig struct {
	// The address to bind to
	BindAddress string
	// The name of this node that will be used to identify the node in the master.
	// This value must match the value provided to the master on startup.
	NodeHost string
	// The host that the master can be reached at (not in use yet)
	MasterHost string
	// The directory that volumes will be stored under
	VolumeDir string

	ClusterDomain string
	ClusterDNS    net.IP

	// a function that returns the appropriate image to use for a named component
	ImageFor func(component string) string

	// The name of the network plugin to activate
	NetworkPluginName string

	// If true, the Kubelet will ignore errors from Docker
	AllowDisabledDocker bool

	// Whether to enable TLS serving
	TLS bool

	// Enable TLS serving
	KubeletCertFile string
	KubeletKeyFile  string

	// ClientCAs will be used to request client certificates in connections to the node.
	// This CertPool should contain all the CAs that will be used for client certificate verification.
	ClientCAs *x509.CertPool

	// A client to connect to the master.
	Client *client.Client
	// A client to connect to Docker
	DockerClient dockertools.DockerInterface
}

func BuildKubernetesNodeConfig(options configapi.NodeConfig) (*NodeConfig, error) {
	kubeClient, _, err := configapi.GetKubeClient(options.MasterKubeConfig)
	if err != nil {
		return nil, err
	}

	if options.NodeName == "localhost" {
		glog.Warningf(`Using "localhost" as node name will not resolve from all locations`)
	}

	var dnsIP net.IP
	if len(options.DNSIP) > 0 {
		dnsIP = net.ParseIP(options.DNSIP)
		if dnsIP == nil {
			return nil, fmt.Errorf("Invalid DNS IP: %s", options.DNSIP)
		}
	}

	clientCAs, err := util.CertPoolFromFile(options.ServingInfo.ClientCA)
	if err != nil {
		return nil, err
	}

	imageTemplate := variable.NewDefaultImageTemplate()
	imageTemplate.Format = options.ImageConfig.Format
	imageTemplate.Latest = options.ImageConfig.Latest

	config := &NodeConfig{
		NodeHost:    options.NodeName,
		BindAddress: options.ServingInfo.BindAddress,

		TLS:             configapi.UseTLS(options.ServingInfo),
		KubeletCertFile: options.ServingInfo.ServerCert.CertFile,
		KubeletKeyFile:  options.ServingInfo.ServerCert.KeyFile,
		ClientCAs:       clientCAs,

		ClusterDomain: options.DNSDomain,
		ClusterDNS:    dnsIP,

		VolumeDir:           options.VolumeDirectory,
		ImageFor:            imageTemplate.ExpandOrDie,
		AllowDisabledDocker: options.AllowDisabledDocker,
		Client:              kubeClient,
	}

	return config, nil
}

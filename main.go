package main

import (
	"context"
	"fmt"
	"log"

	"github.com/hashicorp/go-version"
	"github.com/hashicorp/hc-install/product"
	"github.com/hashicorp/hc-install/releases"
	"github.com/hashicorp/terraform-exec/tfexec"
)

func main() {
	installer := &releases.ExactVersion{
		Product: product.Terraform,
		Version: version.Must(version.NewVersion("1.0.6")),
	}

	fmt.Println("Installing Terraform...")

	execPath, err := installer.Install(context.Background())
	if err != nil {
		log.Fatalf("error installing Terraform: %s", err)
	}

	fmt.Println("Running Terraform...")

	workingDir := "./"
	tf, err := tfexec.NewTerraform(workingDir, execPath)
	if err != nil {
		log.Fatalf("error running NewTerraform: %s", err)
	}

	fmt.Println("Init Terraform...")

	err = tf.Init(context.Background(), tfexec.Upgrade(true))
	if err != nil {
		log.Fatalf("error running Init: %s", err)
	}

	// state, err := tf.Show(context.Background())
	// if err != nil {
	// 	log.Fatalf("error running Show: %s", err)
	// }

	fmt.Println("Plan Terraform...")

	plan, err := tf.Plan(context.Background())
	if err != nil {
		log.Fatalf("error plan tf: %s", err)
	}

	if !plan {
		log.Fatalf("unsuccessful plan tf")
	}

	fmt.Println("Applying and Execute Terraform...")

	err = tf.Apply(context.Background())
	if err != nil {
		log.Fatalf("error apply tf: %s", err)
	}
}

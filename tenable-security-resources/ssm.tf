resource "aws_ssm_document" "scanner_bootstrap" {
  name            = var.ssm_document_name
  document_type   = "Command"
  document_format = "YAML"

  content = <<-DOC
    schemaVersion: '2.2'
    description: 'Bootstrap EC2 instances for Nessus scanner access'
    parameters:
      ParameterName:
        type: String
        description: 'SSM Parameter Store path containing the SSH public key'
      Username:
        type: String
        description: 'Username for the scanner user'
        default: '${var.scanner_username}'
    mainSteps:
      - action: 'aws:runShellScript'
        name: 'createScannerUser'
        inputs:
          runCommand:
            - |
              set -e
              USERNAME="{{ Username }}"
              PARAMETER_NAME="{{ ParameterName }}"

              # Retrieve the SSH public key from Parameter Store
              PUBLIC_KEY=$(aws ssm get-parameter --name "$PARAMETER_NAME" --with-decryption --query 'Parameter.Value' --output text --region {{ global:REGION }})

              # Create user if it doesn't exist
              if ! id -u "$USERNAME" >/dev/null 2>&1; then
                useradd -c 'Nessus User' -d "/home/$USERNAME" -s /bin/bash -m "$USERNAME"
                echo "Created user $USERNAME"
              else
                echo "User $USERNAME already exists"
              fi

              # Setup SSH directory and authorized keys
              mkdir -p "/home/$USERNAME/.ssh"
              echo "$PUBLIC_KEY" > "/home/$USERNAME/.ssh/authorized_keys"
              chmod 700 "/home/$USERNAME/.ssh"
              chmod 600 "/home/$USERNAME/.ssh/authorized_keys"
              chown -R "$USERNAME:$USERNAME" "/home/$USERNAME/.ssh"

              # Setup passwordless sudo
              echo "$USERNAME ALL=(ALL) NOPASSWD: ALL" > "/etc/sudoers.d/$USERNAME"
              chmod 440 "/etc/sudoers.d/$USERNAME"
              visudo -cf "/etc/sudoers.d/$USERNAME"

              echo "Scanner user setup completed successfully"
  DOC

  tags = {
    Name = "Scanner Bootstrap Document"
  }
}

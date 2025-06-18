package duoworkflow

import (
	"io"

	pb "gitlab.com/gitlab-org/modelops/applied-ml/code-suggestions/ai-assist/clients/gopb/contract"

	"google.golang.org/protobuf/encoding/protojson"
)

var marshaler = protojson.MarshalOptions{
	UseProtoNames:   true,
	EmitUnpopulated: true,
}

var unmarshaler = protojson.UnmarshalOptions{
	DiscardUnknown: true,
}

// WorkflowStream represents a bidirectional stream for Duo Workflow communication.
type WorkflowStream interface {
	Recv() ([]byte, error)
	Send([]byte) error
	Close() error
}

type workflowStream struct {
	stream pb.DuoWorkflow_ExecuteWorkflowClient
}

func (s *workflowStream) Recv() ([]byte, error) {
	action, err := s.stream.Recv()
	if err != nil {
		return nil, err
	}

	message, err := marshaler.Marshal(action)
	if err != nil {
		return nil, err
	}

	return message, err
}

func (s *workflowStream) Send(message []byte) error {
	response := &pb.ClientEvent{}
	err := unmarshaler.Unmarshal(message, response)
	if err != nil {
		return err
	}

	err = s.stream.Send(response)
	if err != nil {
		if err == io.EOF {
			// Recv() returns the actual error for client streams.
			_, err = s.stream.Recv()
			return err
		}
		return err
	}
	return nil
}

func (s *workflowStream) Close() error {
	return s.stream.CloseSend()
}

export const metrics = [
  {
    group: 'Kubernetes',
    priority: 1,
    active_metrics: 4,
    metrics_missing_requirements: 0,
  },
  {
    group: 'HAProxy',
    priority: 2,
    active_metrics: 3,
    metrics_missing_requirements: 0,
  },
  {
    group: 'Apache',
    priority: 3,
    active_metrics: 5,
    metrics_missing_requirements: 0,
  },
];

export const missingVarMetrics = [
  {
    group: 'Kubernetes',
    priority: 1,
    active_metrics: 4,
    metrics_missing_requirements: 0,
  },
  {
    group: 'HAProxy',
    priority: 2,
    active_metrics: 3,
    metrics_missing_requirements: 1,
  },
  {
    group: 'Apache',
    priority: 3,
    active_metrics: 5,
    metrics_missing_requirements: 3,
  },
];

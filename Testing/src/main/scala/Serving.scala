package org.template.classification

import io.prediction.controller.LServing

class Serving extends LServing[Query, PredictedResult] {

  override
  def serve(query: Query,
    predictedResults: Seq[PredictedResult]): PredictedResult = {
    new PredictedResult(
        predictedResults.head.label,
        query,
        predictedResults.head.probabilities,
        predictedResults.head.modelType
    )
  }
}

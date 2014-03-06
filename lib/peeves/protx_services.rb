module Peeves
  module ProtxServices
    BASE_URL = {
      :simulator  => 'https://test.sagepay.com/simulator/VSPServerGateway.asp',
      :test       => 'https://test.sagepay.com/gateway/service',
      :live       => 'https://live.sagepay.com/gateway/service'
    }

    SERVICE = {
      :simulator => {
        :payment      => '?Service=VendorRegisterTx',
        :release      => '?Service=VendorReleaseTx',
        :abort        => '?Service=VendorAbortTx',
        :refund       => '?Service=VendorRefundTx',
        :repeat       => '?Service=VendorRepeatTx',
        :void         => '?Service=VendorVoidTx',
        :manual       => lambda { raise Peeves::Error, "MANUAL transactions not supported in simulator mode" },
        :directrefund => lambda { raise Peeves::Error, "DIRECTREFUND transactions not supported in simulator mode" },
        :authorise    => '?Service=VendorAuthoriseTx',
        :cancel       => '?Service=VendorCancelTx'
      },
      :test => {
        :payment      => '/vspserver-register.vsp',
        :release      => '/release.vsp',
        :abort        => '/abort.vsp',
        :refund       => '/refund.vsp',
        :repeat       => '/repeat.vsp',
        :void         => '/void.vsp',
        :manual       => '/manual.vsp',
        :directrefund => '/directrefund.vsp',
        :authorise    => '/authorise.vsp',
        :cancel       => '/cancel.vsp'
      },
      :live => {
        :payment      => '/vspserver-register.vsp',
        :release      => '/release.vsp',
        :abort        => '/abort.vsp',
        :refund       => '/refund.vsp',
        :repeat       => '/repeat.vsp',
        :void         => '/void.vsp',
        :manual       => '/manual.vsp',
        :directrefund => '/directrefund.vsp',
        :authorise    => '/authorise.vsp',
        :cancel       => '/cancel.vsp'
      }
    }
  end
end

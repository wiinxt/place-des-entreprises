module Stats::Matches
  class All < Stats::All
    def transmitted_less_than_72h_stats
      TransmittedLessThan72hStats.new(@params)
    end

    def positioning_rate
      PositioningRate.new(@params)
    end

    def taking_care_rate_stats
      TakingCareRateStats.new(@params)
    end

    def done_rate_stats
      DoneRateStats.new(@params)
    end

    def done_no_help_rate_stats
      DoneNoHelpRateStats.new(@params)
    end

    def done_not_reachable_rate_stats
      DoneNotReachableRateStats.new(@params)
    end

    def not_for_me_rate_stats
      NotForMeRateStats.new(@params)
    end
  end
end

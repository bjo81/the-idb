module V3
  class Nics < Grape::API
    helpers V3::Helpers

    version 'v3'
    format :json

    resource :nics do
      before do
        api_enabled!
        authenticate!
        set_papertrail
      end

      route_param :id, type: Integer, requirements: { id: /[0-9]+/ } do
        desc 'Get a nic by id', success: Nic::Entity
        get do
          can_read!
          n = Nic.find_by_id params[:id]
          error!('Not found', 404) unless n

          n
        end

        desc 'Update a single nic', success: Nic::Entity
        put do
          can_write!
          n = Nic.find_by_fqdn params[:id]
          error!('Not found', 404) unless n

          p = params.select { |k| Nic.attribute_method?(k) }

          n.update_attributes(p)

          n
        end

        desc 'Delete a single nic'
        put do
          can_write!
          n = Nic.find_by_fqdn params[:id]
          error!('Not found', 404) unless n

          n.destroy
        end
      end

      desc 'Return a list of nics, possibly filtered', is_array: true,
                                                       success: Nic::Entity
      get do
        can_read!

        if params['machine']
          if Machine.find_by_fqdn(params['machine'])
            params[:machine_id] = Machine.find_by_fqdn(params['machine']).id
          else
            return []
          end
        end
        params.delete 'machine'

        query = Nic.all
        params.delete('idb_api_token')
        params.each do |key, value|
          keysym = key.to_sym
          query = query.merge(Nic.where(Nic.arel_table[keysym].eq(value)))
        end

        begin
          query.any?
        rescue ActiveRecord::StatementInvalid
          error!('Bad Request', 400)
        end

        present query
      end

      desc 'Create a new nic', success: Nic::Entity
      post do
        can_write!

        p = params.select { |k| Nic.attribute_method?(k) }
        n = Nic.create!(p)
        n
      end
    end
  end
end

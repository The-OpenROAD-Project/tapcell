%module tapcell

%include exception.i
%include std_string.i
%include std_vector.i
%include std_map.i
%{
#include <tapcell.h>
using Placement = Openroad::PowerDistributionNetwork::Placement;

namespace std 
{
	vector<string> get_keys(map<string,vector<Placement> >& k)
	{
		vector<string> rv;
		for(auto& s:k) rv.push_back(s.first);
		return rv;
	}
	
	size_t get_plc_size(vector<Placement>& v)
	{
		return v.size();
	}

	size_t get_num_rows(std::vector<Openroad::PowerDistributionNetwork::Row>& v)
	{
		return v.size();
	}
}
%}
// Part to generate interface from
#pragma SWIG nowarn=305
#pragma SWIG nowarn=401
#pragma SWIG nowarn=511
%include <tapcell.h>

%template(result) 
	std::map<std::string,
		std::vector<Openroad::PowerDistributionNetwork::Placement>
		>;
	
%template(plcvector) std::vector<Openroad::PowerDistributionNetwork::Placement>;
		
%template(symvector) std::vector<Openroad::PowerDistributionNetwork::Symmetry>;

%template(svector) std::vector<std::string>;

%template(rowvector) std::vector<Openroad::PowerDistributionNetwork::Row>;

std::vector<std::string> get_keys(
	std::map<std::string, 	std::vector<Openroad::PowerDistributionNetwork::Placement> >& k
	);
	
size_t get_plc_size(
	std::vector<Openroad::PowerDistributionNetwork::Placement>&
	);
	
size_t get_num_rows(
	std::vector<Openroad::PowerDistributionNetwork::Row>&
	);
